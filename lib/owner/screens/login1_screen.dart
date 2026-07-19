import 'package:erationshop/owner/screens/forgot1_passwrd.dart';
import 'package:erationshop/owner/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart'; // Import the lottie package
import 'package:image_picker/image_picker.dart'; // To capture the image
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http; // For Face++ integration
import 'package:image/image.dart' as img; // For image resizing

class Login1_Screen extends StatefulWidget {
  const Login1_Screen({super.key});

  @override
  State<Login1_Screen> createState() => _Login1_ScreenState();
}

class _Login1_ScreenState extends State<Login1_Screen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController shopid_controller = TextEditingController();
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  bool passwordVisible = true;
  bool loading = false;
  File? _imageFile; // For storing the selected image
  final picker = ImagePicker(); // For picking images

  // Method to pick image from camera and resize it
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

  // Method to upload the image to Face++ for face detection
  Future<String?> _uploadImageToFacePlusPlus() async {
    try {
      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/detect');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = dotenv.env['faceppapikey']!; 
      request.fields['api_secret'] = dotenv.env['faceppsecretkey']!; 
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

  // Method to compare the captured face token with the stored face token
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

  // Function to handle login
  void login() async {
    setState(() {
      loading = true; // Set loading to true while performing login
    });

    if (_formKey.currentState?.validate() ?? false) {
      try {
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
        loading=true;
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

        // Step 4: Query Firestore for a matching Shop Owner document
        final querySnapshot = await FirebaseFirestore.instance
            .collection('Shop Owner')
            .where('email', isEqualTo: email_controller.text)
            .where('shop_id', isEqualTo: shopid_controller.text)
            .get();

        // Check if the document exists
        if (querySnapshot.docs.isEmpty) {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or shop ID')),
          );
          return;
        }

        // Get the matching document (there should be only one)
        final shopData = querySnapshot.docs.first;
        final storedPassword = shopData['password'];
        final storedFaceToken = shopData['face_token'];

        // Step 5: Verify face token
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

        // Step 6: Check if the password matches
        if (password_controller.text == storedPassword) {
          setState(() {
            loading = false;
          });

          // Store the shop_id and shop owner's docId in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('shop_id', shopid_controller.text);
          prefs.setString('shop_owner_doc_id', shopData.id); // Save Firestore doc ID

          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face Verified Successfully !!!')));
          // Proceed to the next screen or main app page after successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OwnerHomeScreen()),
          );
        } else {
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password')),
          );
        }
      } catch (e) {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error during login')),
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
                  const Color.fromARGB(255, 254, 254, 253),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main content (only shown when not loading)
          if (!loading) 
            Padding(
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
                            'asset/logo.jpg', // Replace with your logo
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 55),
                    // "Owner Login" centered header
                    Center(
                      child: Text(
                        'DISTRIBUTER LOGIN',
                        style: GoogleFonts.merriweather(
                          color: const Color.fromARGB(255, 4, 4, 4),
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
                        fillColor: const Color.fromARGB(255, 202, 196, 182),
                        prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                        hintText: 'Enter Email Id',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 7, 7, 7)),
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
                    // Shop ID Field
                    TextFormField(
                      controller: shopid_controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(255, 202, 196, 182),
                        prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                        hintText: 'Enter Store Id',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 15, 14, 14)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter the correct store id";
                        } else if (value.length != 6) {
                          return "Store Id must be 6 digits";
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
                        fillColor: const Color.fromARGB(255, 202, 196, 182),
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
                    // Forgot Password Button (Optional)
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          return Forgot1_Password();
                        }));
                      },
                      child: const Text('Forgot Password?', style: TextStyle(color: Colors.black)),
                    ),
                    SizedBox(height: 50),
                    // Login Button
                    Center(
                      child: ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 163, 163, 164),
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Login', style: TextStyle(fontSize: 18,color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading Indicator (Show when loading)
          if (loading)
            Center(
              child: Lottie.asset(
                'asset/loading.json', // Add the loading animation file path
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
