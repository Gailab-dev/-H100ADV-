package com.disabled.model;

import java.util.Map;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

/**
 * 과태료 부과 사전 통지서 엑셀 파일 다운로드시 필요한 정보들을 모은 DTO
 * @author 지아이랩
 *
 */
@Getter
@Setter
@Builder
public class FineAdvanceNoticeSpec {
	
	// 시트명
	private String sheetName;
	
	// 엑셀 정보
    private String subjectName;         // 대상자: 김00
    private String address;             // 주소
    private String carNumber;           // 차량번호
    private String violationDateTime;   // 위반일시 (표기용 문자열)
    private String violationPlace;      // 위반장소
    private String fineAmount;          // 과태료금액
    private String violationContent;    // 위반내용
    private String applyLawOrMethod;    // 적용방법
    private String reducedAmount;       // 감경금액
    private String opinionDeadline;     // 의견제출기한
    private String ePaymentNumber;      // 전자납부번호
    private String issueDate;           // 2020년 00월 00일 (표기용)
    private String issuerOrg;           // 00시 00구

    // 오른쪽 단속 이미지 2장
    private byte[] photo1;
    private byte[] photo2;

    // 하단 도장 이미지, 수납인 이미지
    private byte[] sealImage;
    private byte[] collectorImage;
    
    /**
     * (선택) eventListDetail에서 가져온 Map 1건으로 Spec을 쉽게 만드는 팩토리
     * - 키 이름은 프로젝트에 맞게 조정해줘.
     */
    public static FineAdvanceNoticeSpec fromEventDetail(
            Map<String, Object> event,
            byte[] photo1, byte[] photo2,
            byte[] sealImage, byte[] collectorImage,
            String subjectName, String address,
            String fineAmount, String applyLawOrMethod,
            String reducedAmount, String opinionDeadline,
            String ePaymentNumber,
            String issueDate, String issuerOrg
    ) {
        return FineAdvanceNoticeSpec.builder()
                .sheetName("사전통지서")
                .subjectName(subjectName)
                .address(address)
                .carNumber(str(event.get("ev_car_num")))
                .violationDateTime(str(event.get("ev_reg_date"))) // 또는 ev_date+시간 조합
                .violationPlace(str(event.get("dv_addr")))        // 상세주소 포함이면 그 키로
                .fineAmount(fineAmount)
                .violationContent(str(event.get("ev_cd")))
                .applyLawOrMethod(applyLawOrMethod)
                .reducedAmount(reducedAmount)
                .opinionDeadline(opinionDeadline)
                .ePaymentNumber(ePaymentNumber)
                .issueDate(issueDate)
                .issuerOrg(issuerOrg)
                .photo1(photo1)
                .photo2(photo2)
                .sealImage(sealImage)
                .collectorImage(collectorImage)
                .build();
    }
    
    // 문자열 변환
    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}
