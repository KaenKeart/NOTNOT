import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'prediction_page.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({super.key});

  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;

  Future<void> _requestPermissions() async {
    if (await Permission.camera.isDenied) {
      await Permission.camera.request();
    }
    if (await Permission.photos.isDenied) {
      await Permission.photos.request();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isPickingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });

        // นำทางไปยังหน้าทำนาย
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PredictionPage(image: _image!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image selected'),
          ),
        );
      }
    } catch (e) {
      print('Failed to pick image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image'),
        ),
      );
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Image',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
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
        decoration: BoxDecoration(
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
                constraints: BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isPickingImage)
                      const CircularProgressIndicator()
                    else if (_image != null)
                      Image.file(
                        _image!,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      )
                    else
                      const Text('No image selected'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Color.fromRGBO(33, 150, 243, 1),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Color.fromRGBO(33, 150, 243, 1)),
                        ),
                        elevation: 6,
                      ).copyWith(
                        shadowColor: MaterialStateProperty.all(
                            Color.fromRGBO(33, 150, 243, 0.4)),
                      ),
                      child: const Text('Take Photo'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Color.fromRGBO(33, 150, 243, 1),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Color.fromRGBO(33, 150, 243, 1)),
                        ),
                        elevation: 6,
                      ).copyWith(
                        shadowColor: MaterialStateProperty.all(
                            Color.fromRGBO(33, 150, 243, 0.4)),
                      ),
                      child: const Text('Choose from Gallery'),
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
