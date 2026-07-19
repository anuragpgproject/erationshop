import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img; // For image resizing
import 'package:http/http.dart' as http; // For Face++ integration
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/user/screens/forgot_password.dart';
import 'package:erationshop/user/screens/signup_screen.dart';
import 'package:erationshop/user/screens/uhome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login_Screen extends StatefulWidget {
  const Login_Screen({super.key});

  @override
  State<Login_Screen> createState() => _Login_ScreenState();
}

class _Login_ScreenState extends State<Login_Screen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController card_controller = TextEditingController();
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  bool passwordVisible = true;
  bool loading = false;
  
  File? _imageFile; // For storing the selected image
  final picker = ImagePicker(); // For picking images

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


// This function will handle the login process with face verification
void login() async {
  setState(() {
    loading = true; // Set loading to true while performing login
  });

  String email = email_controller.text;
  String password = password_controller.text;
  String cardno = card_controller.text;
if (_formKey.currentState?.validate() ?? false) {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // First query the User collection based on card number and email
    QuerySnapshot userSnapshot = await firestore
        .collection('User')
        .where('card_no', isEqualTo: cardno)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      var userDoc = userSnapshot.docs.first;

      // Check if the password matches
      if (userDoc['password'] == password) {
        // Get the card_id from the User document
        String cardId = userDoc['card_id'];

        // Now check if the card_id exists in the Card collection
        DocumentSnapshot cardDoc = await firestore.collection('Card').doc(cardId).get();

        if (cardDoc.exists) {
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

          // Step 4: Verify face token by comparing with stored face_token
          String storedFaceToken = cardDoc['face_token'];
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

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Face Verified Successfully !!!')));
          // If face matches, proceed with login and store card_no in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('card_no', cardno);
          prefs.setString('email', email);

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UhomeScreen()),
          );
        } else {
          // If card doesn't exist in the Card collection, show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Card not found')),
          );
        }
      } else {
        // Incorrect password
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incorrect password')),
        );
      }
    } else {
      // User not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Card number or email does not exist')),
      );
    }
  } catch (e) {
    setState(() {
    loading = false; // Set loading to false after login attempt
  });
    // Handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('An error occurred: $e')),
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
      return ForgotPasswordPage();
    }));
    // Navigate to Forgot Password Screen
  }

  void gotosignup() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Signup_Screen();
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
                  const Color.fromARGB(255, 249, 248, 247),
                  const Color.fromARGB(255, 243, 242, 240),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Main content
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
                  // Center the LOGIN header
                  Text(
                    'LOGIN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.merriweather(
                      color: const Color.fromARGB(255, 10, 10, 10),
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
                  SizedBox(height: 45),
                  // Card Number Field
                  TextFormField(
                    controller: card_controller,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 202, 196, 182),
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      hintText: 'Enter Card No',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 10, 10, 10)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the correct card number";
                      } else if (value.length != 10) {
                        return "Card number must be 10 digits";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  // Email Field
                  TextFormField(
                    controller: email_controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 17, 16, 16)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Enter your email address",
                      filled: true,
                      fillColor:const Color.fromARGB(255, 202, 196, 182),
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email address";
                      }
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return "Please enter a valid email address";
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
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      suffixIconColor: const Color.fromARGB(198, 14, 1, 62),
                      filled: true,
                      fillColor:const Color.fromARGB(255, 202, 196, 182),
                      hintText: 'Enter Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(width: 2, color: const Color.fromARGB(255, 6, 6, 6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                        icon: Icon(passwordVisible ? Icons.visibility : Icons.visibility_off),
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
                  // Reduced size for the login button
                  if (!loading)
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 202, 196, 182)),
                        shadowColor: MaterialStateProperty.all(const Color.fromARGB(255, 62, 55, 5)),
                        elevation: MaterialStateProperty.all(10.0),
                        minimumSize: MaterialStateProperty.all(Size(180, 45)), // Reduced size
                      ),
                      onPressed: login, // Call the login method here
                      child: Text(
                        'LOGIN',
                        style: TextStyle(color: const Color.fromARGB(255, 8, 6, 21), fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(height: 10),
                  // Sign Up Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: TextStyle(color: const Color.fromARGB(255, 50, 3, 27)),
                      ),
                      TextButton(
                        onPressed: gotosignup,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: const Color.fromARGB(255, 23, 5, 32), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Show Lottie animation in the center when loading
          if (loading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3), // Dim the background
                child: Center(
                  child: Lottie.asset(
                    'asset/loading.json', // Path to your animation file
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
