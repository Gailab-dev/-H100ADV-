package com.disabled.backup;

/**
 * 백업 대상 파일 종류. DB(tbl_file_transfer_log.ft_file_kind)에는 enum 이름 그대로 저장한다.
 *  - pullType: module_d /fileSend 요청의 type 값(image/video/audio)
 *  - refType : 참조 종류(event=tbl_event_data, sip_call=tbl_sip_call)
 */
public enum FileKind {

	EVENT_IMAGE1("image", "event"),
	EVENT_IMAGE2("image", "event"),
	EVENT_VIDEO("video", "event"),
	CALL_AUDIO("audio", "sip_call");

	public final String pullType;
	public final String refType;

	FileKind(String pullType, String refType) {
		this.pullType = pullType;
		this.refType = refType;
	}

	/** DB 문자열 → enum. 알 수 없으면 null */
	public static FileKind of(String name) {
		if (name == null) {
			return null;
		}
		try {
			return FileKind.valueOf(name.trim());
		} catch (IllegalArgumentException e) {
			return null;
		}
	}
}
