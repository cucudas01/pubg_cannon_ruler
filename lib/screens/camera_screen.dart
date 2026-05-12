import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../widgets/mortar_painter.dart';
import '../models/map_data.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController controller;
  bool isProcessing = false;
  Offset? playerPos; // 터치로 지정한 내 위치
  Offset? pingPos;   // 형태 인식으로 찾은 핑 위치
  double distance = 0;

  late cv.Mat templateMat;
  bool isTemplateLoaded = false;

  final List<MapData> pubgMaps = [
    MapData("대형 (8km)", 8000),
    MapData("중형 (4km)", 4000),
    MapData("훈련장/소형 (2km)", 2000),
  ];
  late MapData selectedMap;

  @override
  void initState() {
    super.initState();
    selectedMap = pubgMaps[2]; // 기본값 훈련장

    _loadTemplate();

    controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );

    controller.initialize().then((_) async {
      if (!mounted) return;
      await controller.setExposureOffset(-1.5); // 명도 낮춤
      await controller.setFocusMode(FocusMode.auto);
      controller.startImageStream((image) => processImage(image));
      setState(() {});
    });
  }

  // 에셋에서 핑 이미지 로드
  Future<void> _loadTemplate() async {
    try {
      final byteData = await rootBundle.load('assets/ping_template.png');
      final uint8List = byteData.buffer.asUint8List();
      // 그레이스케일로 디코딩하여 연산 속도 향상
      templateMat = cv.imdecode(uint8List, cv.IMREAD_GRAYSCALE);
      isTemplateLoaded = true;
      debugPrint("🎯 템플릿 로드 완료");
    } catch (e) {
      debugPrint("❌ 템플릿 로드 실패: $e");
    }
  }

  void processImage(CameraImage image) async {
    if (isProcessing || !isTemplateLoaded) return;
    isProcessing = true;

    try {
      // 1. 카메라 프레임을 흑백 Mat으로 변환
      final mat = cv.Mat.fromList(image.height, image.width, cv.MatType.CV_8UC1, image.planes[0].bytes);

      // 2. 템플릿 매칭 수행
      final result = cv.matchTemplate(mat, templateMat, cv.TM_CCOEFF_NORMED);

      // 3. [에러 수정 포인트] Record 문법으로 결과 분해
      // image_9cf185.jpg의 에러 원인인 구조 분해 할당입니다.
      final (minVal, maxVal, minLoc, maxLoc) = cv.minMaxLoc(result);

      // 4. 일치율이 60% 이상인 경우 핑으로 인식
      if (maxVal > 0.60) {
        // maxLoc.x와 maxLoc.y를 사용하여 중심 좌표 계산
        double detectedX = maxLoc.x.toDouble() + (templateMat.cols / 2);
        double detectedY = maxLoc.y.toDouble() + (templateMat.rows / 2);

        setState(() {
          if (playerPos != null) {
            // 내 위치와 30픽셀 이상 떨어진 대상만 핑으로 인정
            double distToPlayer = sqrt(pow(detectedX - playerPos!.dx, 2) + pow(detectedY - playerPos!.dy, 2));
            if (distToPlayer > 30) {
              pingPos = Offset(detectedX, detectedY);
              _calculateDistance();
            }
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ 분석 에러: $e");
    } finally {
      await Future.delayed(const Duration(milliseconds: 100));
      isProcessing = false;
    }
  }

  void _calculateDistance() {
    if (playerPos == null || pingPos == null) return;

    double pixelDist = sqrt(pow(pingPos!.dx - playerPos!.dx, 2) + pow(pingPos!.dy - playerPos!.dy, 2));

    if (controller.value.previewSize != null) {
      double sensorWidth = controller.value.previewSize!.height;
      setState(() {
        distance = (pixelDist / sensorWidth) * selectedMap.realSizeMeter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
          builder: (context, constraints) {
            final double aspectRatio = controller.value.aspectRatio;

            return Stack(
              children: [
                // 카메라 화면 (비율 유지)
                Center(
                  child: AspectRatio(
                    aspectRatio: 1 / aspectRatio,
                    child: CameraPreview(controller),
                  ),
                ),

                // 터치 및 그리기 레이어
                Positioned.fill(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1 / aspectRatio,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          setState(() {
                            playerPos = details.localPosition;
                            debugPrint("🎯 내 위치 터치됨: $playerPos");
                            _calculateDistance();
                          });
                        },
                        child: CustomPaint(
                          painter: MortarPainter(
                            playerPos: playerPos,
                            pingPos: pingPos,
                            distance: distance,
                            teamColor: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // UI 메뉴
                Positioned(
                  bottom: 30, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(15)
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            "${distance.toStringAsFixed(1)}m",
                            style: const TextStyle(
                                fontSize: 40,
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold
                            )
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButton<MapData>(
                                isExpanded: true,
                                value: selectedMap,
                                dropdownColor: Colors.black87,
                                items: pubgMaps.map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.name, style: const TextStyle(color: Colors.white))
                                )).toList(),
                                onChanged: (v) => setState(() {
                                  selectedMap = v!;
                                  _calculateDistance();
                                }),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () => setState(() {
                                playerPos = null;
                                pingPos = null;
                                distance = 0;
                              }),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}