package com.disabled.service;

import java.nio.file.Path;

import com.disabled.roi.RoiActor;
import com.disabled.roi.RoiResult;
import com.fasterxml.jackson.databind.JsonNode;

/**
 * 웹 ROI 설정 서비스(34번 작업계획서 §5.2). 모든 메서드는 HTTP 상태코드와 JSON 본문을 담은 RoiResult 를 돌려준다.
 * 권한(u_grade 25/30)·CSRF 는 인터셉터·컨트롤러가 처리하고, 여기서는 장비 조회·검증·이력·중계만 한다.
 */
public interface RoiService {

	/** 편집 화면 머리말용 장비 정보(장비명·시리얼). 장비가 없으면 404. */
	RoiResult deviceInfo(int deviceId);

	/** 장비의 현재 ROI(+해시)를 읽고, DB 와 다르면 SYNC 이력을 남긴다. */
	RoiResult load(int deviceId);

	/** 장비에서 Cam1/Cam2 스냅샷을 받아 서버 임시 폴더에 저장한다. */
	RoiResult snapshot(int deviceId, RoiActor actor);

	/**
	 * ROI 저장. rollbackRhId 가 null 이 아니면 해당 이력의 원문으로 되돌리며(ROLLBACK), 이때 rois 는 쓰지 않는다.
	 * baseHash 는 편집을 시작할 때 받은 장비 해시(파일이 없었으면 빈 문자열).
	 */
	RoiResult save(int deviceId, JsonNode rois, String baseHash, Long rollbackRhId, RoiActor actor);

	/** 시간 초과로 PENDING 이 된 이력의 결과를 장비 해시 비교로 확정한다. */
	RoiResult check(long rhId, RoiActor actor);

	/** 장비의 이력 목록(최신순). */
	RoiResult history(int deviceId, int limit);

	/** 이력 한 건의 상세(ROI + 기준 스냅샷 목록). */
	RoiResult historyDetail(long rhId);

	/** 본인 임시 스냅샷 파일(없으면 null). 경로는 서버가 계정·시리얼·카메라로 결정한다. */
	Path tempSnapshot(int deviceId, String camera, RoiActor actor);

	/** 기준 스냅샷 파일(DB 의 rs_id 로 결정, 없거나 경로가 규칙에 맞지 않으면 null). */
	Path baselineSnapshot(long rsId);
}
