# 엣지 저장 경로 안내

- 기준: 엣지 Jetson, 코드 폴더 `~/H100/system`
- 기존 `recorded` 폴더는 `output`으로 이름 변경 (하위 구조 동일)

## 1. 이미지 / 영상 / 음성 저장 폴더

- 위반 이벤트 이미지: `~/H100/output/image`
- 위반 이벤트 영상: `~/H100/output/video`
- 상시 녹화 영상: `~/H100/output/video/always`
- SIP 통화 녹음(음성): `~/H100/output/voice`

## 2. rois.json

- `~/H100/system/rois.json` (코드 폴더 바로 안)

## 3. ROI 그리기용 스냅샷 이미지

- `~/H100/output/roi_snapshot`
- 동작 (구현 예정)
  - 서버에서 ROI 설정 버튼 클릭 시 엣지로 요청 로그 전송
  - 엣지 수신 후 PTZ 카메라는 초기 설정 화각으로 이동 → 정지 후 캡처
  - 캡처 이미지를 위 폴더에 저장
