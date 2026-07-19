import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img; // For image resizing
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/admin/screens/admin_forgot.dart';
import 'package:erationshop/admin/screens/admin_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart'; // Add Lottie import
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // For Face++ integration


class Admin_Login extends StatefulWidget {
  const Admin_Login({super.key});

  @override
  State<Admin_Login> createState() => _Admin_LoginState();
}

class _Admin_LoginState extends State<Admin_Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  bool passwordVisible = true;
  bool loading = false;
  
  File? _imageFile; // For storing the selected image
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    setState(() {
      loading = true;
    });

    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Load the image file
      var image = img.decodeImage(await _imageFile!.readAsBytes());

      if (image != null) {
        // Resize the image to a smaller size, e.g., 600x600
        var resizedImage = img.copyResize(image, width: 600);

        // Save the resized image back to a file
        final compressedFile = File(pickedFile.path)..writeAsBytesSync(img.encodeJpg(resizedImage));

        setState(() {
          _imageFile = compressedFile;
        });
      }

      setState(() {
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }
  Future<String?> _uploadImageToFacePlusPlus() async {
    try {
      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/detect');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = dotenv.env['faceppapikey']!; // Replace with your API Key
      request.fields['api_secret'] = dotenv.env['faceppsecretkey']!; // Replace with your API Secret
      request.files.add(await http.MultipartFile.fromPath('image_file', _imageFile!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        var responseData = json.decode(responseBody.body);

        if (responseData['faces'] != null && responseData['faces'].isNotEmpty) {
          var faceToken = responseData['faces'][0]['face_token'];
          return faceToken;
        } else {
          return null; // No faces detected
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<bool> _compareFaces(String? faceToken, String storedFaceToken) async {
    if (faceToken == null) {
      return false;
    }

    try {
      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = dotenv.env['faceppapikey']!; // Replace with your API Key
      request.fields['api_secret'] = dotenv.env['faceppsecretkey']!; // Replace with your API Secret
      request.fields['face_token1'] = faceToken;
      request.fields['face_token2'] = storedFaceToken;

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        var responseData = json.decode(responseBody.body);
        double confidence = responseData['confidence'];  // Similarity score

        if (confidence > 80.0) {
          return true; // Faces match
        } else {
          return false; // Faces don't match
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Method to login using Firestore (without Firebase Authentication)
  void login() async {
  setState(() {
    loading = true; // Set loading to true while performing login
  });

  String email = email_controller.text;
  String password = password_controller.text;
  
  if (_formKey.currentState?.validate() ?? false) {
    try {
      // Check for recovery credentials before proceeding
      if (email == "recovery@gmail.com" && password == "recovery") {
        // If recovery credentials are entered, skip face comparison and go directly to the homepage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);

        // Notify user and navigate to AdminHome screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
        setState(() {
          loading = false;
        });
        return;
      }

      // Step 1: Capture the face image
      await _pickImage();
      if (_imageFile == null) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture your face image')),
        );
        return;
      }

      // Step 2: Show "Processing Image" message while uploading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing image, please wait...')),
      );
      loading = true;

      // Step 3: Upload the image and detect the face
      String? faceToken = await _uploadImageToFacePlusPlus();
      if (faceToken == null) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected. Please try again.')),
        );
        return;
      }

      // Step 4: Query Firestore for the admin with matching email and password
      var adminSnapshot = await FirebaseFirestore.instance
          .collection('Admin')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        // Get the stored face token from Firestore
        final adminData = adminSnapshot.docs.first;
        final storedFaceToken = adminData['face_token'];

        // Step 5: Verify the face token
        bool isFaceMatched = await _compareFaces(faceToken, storedFaceToken);
        if (!isFaceMatched) {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face does not match the stored image')),
          );
          return;
        }

        // Step 6: Login successful, store email in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);

        // Notify user and navigate to AdminHome screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
      } else {
        // If no matching admin is found, show an error
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    } catch (e) {
      // Handle errors during Firestore query or image processing
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  } else {
    setState(() {
      loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please fill in all fields')),
    );
  }
}


  void forgotpassword() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return AdminForgotPasswordPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 255, 255, 255),
                  const Color.fromARGB(255, 255, 255, 255),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Main content
          Opacity(
            opacity: loading ? 0.3 : 1.0, // Apply low opacity when loading is true
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    SizedBox(height: 80),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            'asset/logo.jpg',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 55),
                    // "Admin Login" centered header
                    Center(
                      child: Text(
                        'ADMIN LOGIN',
                        style: GoogleFonts.merriweather(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 28.0,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: const Color.fromARGB(255, 160, 155, 155),
                              offset: Offset(-3.0, 3.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 45),
                    // Email Field
                    TextFormField(
                      controller: email_controller,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:const Color.fromARGB(255, 202, 196, 182),
                        prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                        hintText: 'Enter Email Id',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 0, 0, 0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter the email id";
                        } else if (!RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                          return "Please enter a valid email";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    // Password Field
                    TextFormField(
                      controller: password_controller,
                      obscureText: passwordVisible,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:const Color.fromARGB(255, 202, 196, 182),
                        hintText: 'Enter Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 0, 0, 0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              passwordVisible = !passwordVisible;
                            });
                          },
                          icon: Icon(
                            passwordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter correct password";
                        } else if (value.length < 8) {
                          return "Password must be at least 8 characters";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10),
                    // Forgot Password Button
                    TextButton(
                      onPressed: forgotpassword,
                      child: Text(
                        'Forgot password ?',
                        style: TextStyle(color: const Color.fromARGB(255, 11, 8, 1), fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 40),
                    // Login Button with a smaller width
                    Center(
                      child: SizedBox(
                        width: 250, // Reduced width
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 202, 196, 182)),
                            shadowColor: MaterialStateProperty.all(const Color.fromARGB(255, 62, 55, 5)),
                            elevation: MaterialStateProperty.all(10.0),
                          ),
                          onPressed: login, // Call the login method here
                          child: Text(
                            'LOGIN',
                            style: TextStyle(color: const Color.fromARGB(255, 8, 6, 21), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),

          // Lottie animation (loading) positioned in the center
          if (loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3), // Dim the background
                child: Center(
                  child: Lottie.asset(
                    'asset/loading.json', // Path to your Lottie animation file
                    width: 150,
                    height: 150,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
