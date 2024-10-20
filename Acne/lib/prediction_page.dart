import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'acnelevelspage.dart';

class PredictionPage extends StatefulWidget {
  final File image;

  const PredictionPage({Key? key, required this.image}) : super(key: key);

  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  String? _predictionResult;
  String? _predictionAccuracy; // เพิ่มตัวแปรสำหรับความแม่นยำ
  bool _isAnalyzing = false;

  // ปรับปรุง Dio ให้มี timeout
  Dio dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20), // 20 วินาที
    receiveTimeout: const Duration(seconds: 20), // 20 วินาที
  ));

  Future<void> _analyzeImage(File imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _predictionResult = null;
      _predictionAccuracy = null; // รีเซ็ตความแม่นยำ
    });

    try {
      String url = 'http://172.20.43.69:5001/predict';
      String filename = basename(imageFile.path);

      FormData formData = FormData.fromMap({
        'image':
            await MultipartFile.fromFile(imageFile.path, filename: filename),
      });

      Response response = await dio.post(url, data: formData);

      if (response.statusCode == 200) {
        setState(() {
          _predictionResult = response.data['predicted_class']; // ระดับสิว
          // ปรับความแม่นยำให้แสดงผลเป็นเปอร์เซ็นต์
          double accuracy = (response.data['predictions'] as List)
                  .reduce((a, b) => a + b)
                  .toDouble() *
              100; // คูณด้วย 100 เพื่อให้เป็นเปอร์เซ็นต์
          _predictionAccuracy =
              accuracy.toStringAsFixed(2); // แสดงความแม่นยำ 2 ตำแหน่ง
          _isAnalyzing = false;
        });
      } else {
        throw Exception('Failed to analyze image');
      }
    } catch (error) {
      setState(() {
        _isAnalyzing = false;
        _predictionResult = 'Error: $error';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _analyzeImage(widget.image);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prediction Results',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(33, 150, 243, 0.8),
                Color.fromRGBO(33, 150, 243, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(33, 150, 243, 0.1),
              Color.fromRGBO(33, 150, 243, 0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 4,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              widget.image,
                              width: 320,
                              height: 320,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_isAnalyzing)
                          Container(
                            width: 320,
                            height: 320,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Analyzing...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!_isAnalyzing && _predictionResult != null)
                      Column(
                        children: [
                          Text(
                            'Acne Level: $_predictionResult',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Accuracy: $_predictionAccuracy%', // แสดงความแม่นยำ
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AcneLevelsPage(
                                    acneLevel: _predictionResult!,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: const BorderSide(color: Colors.blue),
                              elevation: 6,
                            ).copyWith(
                              shadowColor: MaterialStateProperty.all(
                                Colors.blue.withOpacity(0.4),
                              ),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    if (_isAnalyzing)
                      const CircularProgressIndicator(), // สัญลักษณ์กำลังประมวลผล
                    if (!_isAnalyzing && _predictionResult == null)
                      const Text(
                        'Prediction Failed',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
