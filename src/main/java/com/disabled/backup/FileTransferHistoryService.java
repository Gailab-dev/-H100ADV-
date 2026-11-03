package com.disabled.backup;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.disabled.backup.DeviceFileFetcher.FetchOutcome;
import com.disabled.mapper.FileTransferMapper;

/**
 * 파일 전송 이력(tbl_file_transfer_log) 기록 담당 — 스케줄러와 이벤트 삭제 흐름이 공유한다.
 * 이벤트 플래그(ev_has_img/ev_has_mov/sc_has_audio)는 "검증 완료(VERIFIED) 시에만" 여기서 올린다(내리지 않는다).
 */
@Service
public class FileTransferHistoryService {

	private static final Logger logger = LoggerFactory.getLogger(FileTransferHistoryService.class);

	private static final DateTimeFormatter YMD = DateTimeFormatter.ofPattern("yyyyMMdd");

	@Autowired
	private FileTransferMapper fileTransferMapper;

	/** 하루치(대상일 KST) 이벤트 파일·통화 음성을 PENDING 으로 등록한다(이미 있으면 유지). 새로 등록된 건수 반환 */
	public int registerForDate(LocalDate targetDate) {
		String ymd = targetDate.format(YMD);
		String ymdNext = targetDate.plusDays(1).format(YMD);
		int added = 0;
		for (FileKind kind : new FileKind[] { FileKind.EVENT_IMAGE1, FileKind.EVENT_IMAGE2, FileKind.EVENT_VIDEO }) {
			added += Math.max(0, fileTransferMapper.registerEventFiles(kind.name(), ymd, ymdNext, null));
		}
		added += Math.max(0, fileTransferMapper.registerCallAudio(ymd));
		return added;
	}

	/** 이벤트 한 건의 기대 파일(이미지1·이미지2·영상)을 등록한다(이벤트 삭제 흐름용, 이미 있으면 유지) */
	public void registerForEvent(Integer evId) {
		for (FileKind kind : new FileKind[] { FileKind.EVENT_IMAGE1, FileKind.EVENT_IMAGE2, FileKind.EVENT_VIDEO }) {
			fileTransferMapper.registerEventFiles(kind.name(), null, null, evId);
		}
	}

	public List<Map<String, Object>> findByEvent(Integer evId) {
		return fileTransferMapper.selectByEvent(evId);
	}

	/** 판정 결과를 이력에 반영하고, VERIFIED 이면 이벤트 플래그를 갱신한다 */
	public void applyOutcome(long ftId, FileKind kind, Integer refId, FetchOutcome o) {
		if (o.isVerified()) {
			fileTransferMapper.markVerified(ftId, o.attempts, o.deviceBytes, o.serverBytes);
			updateFlagAfterVerified(kind, refId);
		} else if (o.isMissing()) {
			fileTransferMapper.markMissing(ftId, o.attempts);
		} else {
			fileTransferMapper.markFailed(ftId, o.attempts, o.errorCode, o.deviceBytes);
		}
	}

	private void updateFlagAfterVerified(FileKind kind, Integer refId) {
		if (refId == null) {
			return;
		}
		try {
			switch (kind) {
			case EVENT_IMAGE1:
			case EVENT_IMAGE2:
				fileTransferMapper.updateEvHasImgIfVerified(refId);
				break;
			case EVENT_VIDEO:
				fileTransferMapper.updateEvHasMovIfVerified(refId);
				break;
			case CALL_AUDIO:
				fileTransferMapper.updateScHasAudioIfVerified(refId);
				break;
			default:
				break;
			}
		} catch (RuntimeException e) {
			// 플래그 갱신 실패가 검증 기록을 되돌리지 않는다(다음 실행에서 이미 VERIFIED 로 건너뛰므로 로그로 남긴다)
			logger.error("[FileBackup] 검증 후 플래그 갱신 실패 kind={} refId={}", kind, refId, e);
		}
	}

	/** 이벤트 삭제 확정 기록: 해당 이벤트의 이력 행을 DELETED_EVENT 로 바꾸고 원 ev_id·삭제자·시각·원래 경로를 남긴다 */
	public int markEventDeleted(Integer evId, Integer deletedBy, ServerFileLocator locator) {
		int n = 0;
		for (Map<String, Object> row : fileTransferMapper.selectByEvent(evId)) {
			FileKind kind = FileKind.of(String.valueOf(row.get("ft_file_kind")));
			String name = row.get("ft_file_name") == null ? null : row.get("ft_file_name").toString();
			String orig = (kind == null) ? null : locator.originalPath(kind, name);
			if (orig == null) {
				orig = name; // 경로를 알 수 없으면 최소한 파일명을 남긴다
			}
			long ftId = ((Number) row.get("ft_id")).longValue();
			n += fileTransferMapper.markDeletedEventRow(ftId, deletedBy, orig);
		}
		return n;
	}
}
