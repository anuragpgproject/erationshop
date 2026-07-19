import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;

class AdminFaceCaptureForShopScreen extends StatefulWidget {
  @override
  _AdminFaceCaptureForShopScreenState createState() => _AdminFaceCaptureForShopScreenState();
}

class _AdminFaceCaptureForShopScreenState extends State<AdminFaceCaptureForShopScreen> {
  File? _imageFile;
  final picker = ImagePicker();
  TextEditingController shopIdController = TextEditingController();
  bool isLoading = false;

  // Method to pick image using camera
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadImageToFacePlusPlus() async {
    try {
      if (_imageFile == null) {
        throw Exception('No image file selected.');
      }

      // Load image and resize it efficiently
      img.Image image = img.decodeImage(_imageFile!.readAsBytesSync())!;
      img.Image resizedImage = img.copyResize(image, width: 800); // Resize to 800px width to maintain detail

      // Compress image slightly for faster upload while maintaining detail
      final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85); // quality=85 for good quality and fast upload

      // Save resized and compressed image to a temporary file
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/resized_image.jpg');
      await tempFile.writeAsBytes(compressedImageBytes);

      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/detect');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = dotenv.env['faceppapikey']!; // Replace with your API Key
      request.fields['api_secret'] = dotenv.env['faceppsecretkey']!; // Replace with your API Secret
      request.files.add(await http.MultipartFile.fromPath('image_file', tempFile.path));

      var response = await request.send();
      var responseBody = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        var responseData = json.decode(responseBody.body);

        if (responseData['faces'] != null && responseData['faces'].isNotEmpty) {
          var faceToken = responseData['faces'][0]['face_token'];
          return faceToken;
        } else {
          throw Exception('No face detected in the image.');
        }
      } else {
        var responseData = json.decode(responseBody.body);
        var errorMessage = responseData['error_message'] ?? 'Unknown error';
        throw Exception('Face++ API error: $errorMessage');
      }
    } catch (e) {
      throw Exception('Error with Face++ API: $e');
    }
  }

  // Method to save face_token to Firestore
  Future<void> _saveFaceIdToFirestore(String shopId, String faceToken) async {
    try {
      // Check if the shop exists in the Shop Owner collection
      var shopSnapshot = await FirebaseFirestore.instance
          .collection('Shop Owner')
          .where('shop_id', isEqualTo: shopId)
          .limit(1)
          .get();

      if (shopSnapshot.docs.isEmpty) {
        _showDialog('Error', 'Shop ID not found.');
        return;
      }

      // Update the corresponding shop document with the face_token
      await FirebaseFirestore.instance.collection('Shop Owner').doc(shopSnapshot.docs.first.id).update({
        'face_token': faceToken,  // Store the Face++ face_token
      });

      _showDialog('Success', 'Face image has been stored successfully.');
    } catch (e) {
      _showDialog('Error', 'Failed to save face image to Firestore: $e');
    }
  }

  // Method to show dialog with message
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Submit method to handle the entire flow
  Future<void> _submit() async {
    if (shopIdController.text.isEmpty || _imageFile == null) {
      _showDialog('Error', 'Please provide both shop ID and image');
      return;
    }

    setState(() {
      isLoading = true;  // Start loading
    });

    try {
      // Upload image to Face++ and get the face_token
      String faceToken = await _uploadImageToFacePlusPlus();

      // Save the face_token in Firestore under the corresponding shop_id in the Shop Owner collection
      await _saveFaceIdToFirestore(shopIdController.text, faceToken);
    } catch (e) {
      _showDialog('Error', e.toString());
    } finally {
      setState(() {
        isLoading = false;  // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Face Capture', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: shopIdController,
              decoration: InputDecoration(labelText: 'Shop ID'),
            ),
            SizedBox(height: 20),
            _imageFile == null
                ? Text('No image selected.')
                : Image.file(_imageFile!, width: 100, height: 100),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Capture/Update Face Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? CircularProgressIndicator(color: const Color.fromARGB(255, 255, 0, 0))
                  : Text('Save Face ID'),
            ),
          ],
        ),
      ),
    );
  }
}
