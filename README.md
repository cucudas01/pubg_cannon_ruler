# 🎯 PUBG Mortar Distance Calculator (Experimental)
카메라 스트림과 OpenCV를 활용하여 배틀그라운드 게임 내 박격포 사거리를 실시간으로 계산하려 했던 시도 기록입니다.

## 1. 프로젝트 목표
- 스마트폰 카메라로 모니터의 지도를 비추어 '내 위치'와 '핑(Marker)' 사이의 실제 거리를 연산.

## 2. 사용 기술
- **Framework**: Flutter
- **Library**: opencv_dart (Template Matching)
- **HardWare**: Camera API (Real-time Stream)

## 3. 핵심 로직 및 시도
- **HSV Color Filtering**: 초기에는 노란색 핑을 색상으로 추적하려 했으나 지형지물의 색상 간섭으로 실패.
- **Template Matching**: 핑의 형태(이미지 조각)를 비교하여 인식하는 방식으로 전환하여 정확도 향상 시도.
- **Coordinate Mapping**: 카메라 프레임의 픽셀 좌표를 게임 내 실제 미터(m) 단위로 환산하는 공식 적용.

## 4. 기술적 한계 및 배운 점 (Troubleshooting)
- **환경 의존성**: 모니터의 밝기, 촬영 각도, 외부 광원에 따라 OpenCV의 인식 신뢰도가 크게 변하는 것을 확인.
- **스케일링 문제**: 지도의 확대/축소 비율에 따라 고정된 템플릿 이미지로 인식하는 데 한계가 있음을 체감.
- **결론**: 환경 제어가 불가능한 상황에서의 이미지 처리 한계를 극복하기 위해, 향후에는 딥러닝 기반의 객체 탐지(Object Detection) 모델 도입이 필요함을 깨달음.