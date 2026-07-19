import 'dart:io';
import 'package:erationshop/user/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON parsing
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class Signup_Screen extends StatefulWidget {
  const Signup_Screen({super.key});

  @override
  State<Signup_Screen> createState() => _Signup_ScreenState();
}

class _Signup_ScreenState extends State<Signup_Screen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController name_controller = TextEditingController();
  TextEditingController card_controller = TextEditingController();
  TextEditingController email_controller = TextEditingController();
  TextEditingController password_controller = TextEditingController();
  bool passwordVisible = true;
  bool loading = false;
  File? _imageFile; // For storing the selected image
  final picker = ImagePicker(); // For picking images

  // Method to navigate to Login Screen
  void gotologin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Login_Screen();
    }));
  }
Future<void> _pickImage() async {
  setState(() {
    loading = true; // Show loading spinner while capturing
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

      print("Resized image path: ${_imageFile?.path}"); // Debugging
    }

    setState(() {
      loading = false; // Image captured, stop loading
    });

    // Inform user that image is captured
    _showDialog("Image Captured", "Your image has been captured and is being processed.");
  } else {
    setState(() {
      loading = false;
    });
    _showDialog("Error", "No image captured. Please try again.");
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

      print("Face++ Response: $responseData"); // Log the full response from Face++

      if (responseData['faces'] != null && responseData['faces'].isNotEmpty) {
        var faceToken = responseData['faces'][0]['face_token'];
        return faceToken;
      } else {
        return null; // No faces detected
      }
    } else {
      print("Failed to upload image. Status code: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error in image upload: $e");
    return null;
  }
}


  Future<bool> _verifyFaceToken(String faceToken) async {
    try {
      // Check if card exists in the Card collection (for verification)
      QuerySnapshot cardSnapshot = await FirebaseFirestore.instance
          .collection('Card')
          .where('card_no', isEqualTo: card_controller.text)
          .limit(1)
          .get();

      if (cardSnapshot.docs.isEmpty) {
        return false;
      }

      // Retrieve the stored face_token from the card document in Firestore
      String storedFaceToken = cardSnapshot.docs.first['face_token'];

      // Compare the face tokens
      if (storedFaceToken != faceToken) {
        return false;
      }
      return true;
    } catch (e) {
      return false; // Return false if there's an error with face verification
    }
  }

  // Modify the signp method to call the _pickImage before face verification
Future<void> signp() async {
  setState(() {
    loading = true;
  });
if (_formKey.currentState?.validate() ?? false) {

  try {
    // Step 1: Capture the face image
    await _pickImage();
    if (_imageFile == null) {
      setState(() {
        loading = false;
      });
      _showDialog("Error", "No image selected. Please capture an image.");
      return; // Exit if no image is captured
    }
    // Step 2: Upload the image and detect the face concurrently with other checks
    String? faceToken = await _uploadImageToFacePlusPlus();
    if (faceToken == null) {
      setState(() {
        loading = false;
      });
      _showDialog("Error", "No face detected. Please try again.");
      return;
    }

    // Step 3: Query Firestore and compare face token concurrently
    var userQuery = FirebaseFirestore.instance.collection('User')
        .where('card_no', isEqualTo: card_controller.text)
        .limit(1)
        .get();

    var cardQuery = FirebaseFirestore.instance.collection('Card')
        .where('card_no', isEqualTo: card_controller.text)
        .limit(1)
        .get();

    var results = await Future.wait([userQuery, cardQuery]);

    QuerySnapshot userSnapshot = results[0];
    QuerySnapshot cardSnapshot = results[1];

    if (userSnapshot.docs.isNotEmpty) {
      setState(() {
        loading = false;
      });
      _showDialog("Already Registered", "This card number is already registered. Please log in.");
      return;
    }

    if (cardSnapshot.docs.isEmpty) {
      setState(() {
        loading = false;
      });
      _showDialog("Error", "Card number does not exist!");
      return;
    }

    // Proceed with name matching and face verification
    String ownerName = cardSnapshot.docs.first['owner_name'];
    if (ownerName != name_controller.text) {
      setState(() {
        loading = false;
      });
      _showDialog("Error", "The name does not match the card's owner name.");
      return;
    }

    String storedFaceToken = cardSnapshot.docs.first['face_token'];
    bool isFaceMatched = await _compareFaces(faceToken, storedFaceToken);

    if (!isFaceMatched) {
      setState(() {
        loading = false;
      });
      _showDialog("Error", "Face does not match the stored image.");
      return;
    }

    // Store user data after successful signup
    DateTime lastPurchaseDate = DateTime.now().subtract(Duration(days: 31));

    await FirebaseFirestore.instance.collection('User').add({
      'name': name_controller.text,
      'card_no': card_controller.text,
      'card_id': cardSnapshot.docs.first.id,
      'email': email_controller.text,
      'password': password_controller.text,
      'created_at': FieldValue.serverTimestamp(),
      'last_purchase_date': lastPurchaseDate,
    });

    setState(() {
      loading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Login_Screen();
        },
      ),
    );
    _showDialog("Success !!", "Face Verification Successful...");
  } catch (e) {
    setState(() {
      loading = false;
    });
    _showDialog("Error", e.toString());
  }
}
else {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
    }
  
}

  // Method to compare the captured face token with the stored face token
  Future<bool> _compareFaces(String? faceToken, String storedFaceToken) async {
    if (faceToken == null) {
      return false; // Return false if the face token is null
    }

    try {
      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = dotenv.env['faceppapikey']!; // Replace with your API Key
      request.fields['api_secret'] = dotenv.env['faceppsecretkey']!; // Replace with your API Secret
      request.fields['face_token1'] = faceToken;  // The token of the captured face
      request.fields['face_token2'] = storedFaceToken;  // The stored token from Firestore

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        var responseData = json.decode(responseBody.body);
        double confidence = responseData['confidence'];  // Similarity score

        // Step 6: If confidence is high (you can adjust the threshold)
        if (confidence > 80.0) {
          return true; // Faces match
        } else {
          return false; // Faces don't match
        }
      } else {
        return false; // Return false if the comparison fails
      }
    } catch (e) {
      return false; // Return false if there's an error with Face++ comparison API
    }
  }

  // Function to show a dialog with a custom title and message
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(  // Wrap the body in a SingleChildScrollView to make the page scrollable
        child: Container(
          width: double.infinity,  // Ensure the container takes up full width
          height: MediaQuery.of(context).size.height,  // Ensure the container takes up the full height of the screen
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 252, 252, 252),
                const Color.fromARGB(255, 255, 255, 255),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
            child: Form(
              key: _formKey,
              child: Column(
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
                  SizedBox(height: 45),
                  Text(
                    'SIGN UP',
                    style: GoogleFonts.merriweather(
                      color: const Color.fromARGB(255, 14, 14, 14),
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
                  TextFormField(
                    controller: name_controller,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color.fromARGB(255, 11, 11, 11)),
                          borderRadius: BorderRadius.circular(10)),
                      hintText: "Enter card owner's name",
                      filled: true,
                      fillColor:const Color.fromARGB(255, 202, 196, 182),
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the owner's name";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: card_controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(255, 202, 196, 182),
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      hintText: 'Enter Card No',
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color.fromARGB(255, 10, 10, 10)),
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the card number";
                      } else if (value.length != 10) {
                        return "Card number must be 10 digits";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: email_controller,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 2,
                          color: const Color.fromARGB(255, 14, 13, 13),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Enter your email address",
                      filled: true,
                      fillColor: const Color.fromARGB(255, 202, 196, 182),
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
                  TextFormField(
                    controller: password_controller,
                    obscureText: passwordVisible,
                    decoration: InputDecoration(
                      prefixIconColor: const Color.fromARGB(255, 23, 2, 57),
                      suffixIconColor: const Color.fromARGB(198, 14, 1, 62),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 202, 196, 182),
                      hintText: 'Create Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(
                          borderSide: BorderSide(
                              width: 2,
                              color: const Color.fromARGB(255, 7, 7, 7)),
                          borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                        icon: Icon(
                          passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter a password";
                      } else if (value.length < 8) {
                        return "Password must be at least 8 characters";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40),
                  loading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                                const Color.fromARGB(255, 202, 196, 182)),
                            shadowColor: MaterialStateProperty.all(
                                const Color.fromARGB(255, 62, 55, 5)),
                            elevation: MaterialStateProperty.all(10.0),
                          ),
                          onPressed: signp,
                          child: Text(
                            'SIGN UP',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 8, 6, 21),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already signed up?',
                        style: TextStyle(
                            color: const Color.fromARGB(255, 1, 4, 21),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'merriweather'),
                      ),
                      TextButton(
                        onPressed: () {
                          gotologin();
                        },
                        child: Text(
                          'Login here',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'merriweather',
                              color: const Color.fromARGB(255, 46, 21, 185)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
