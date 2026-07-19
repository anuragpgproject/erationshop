import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/user/screens/user_feedback.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:erationshop/user/screens/user_card.dart';
import 'package:erationshop/user/screens/user_notification.dart';
import 'package:erationshop/user/screens/user_outlet.dart';
import 'package:erationshop/user/screens/user_profile.dart';
import 'package:erationshop/user/screens/user_purchase.dart';
import 'package:flutter/services.dart'; 
import 'package:erationshop/user/screens/chatbot.dart'; 

class UhomeScreen extends StatefulWidget {
  const UhomeScreen({super.key});

  @override
  State<UhomeScreen> createState() => _UhomeScreenState();
}

class _UhomeScreenState extends State<UhomeScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  
  bool loading = false;
  bool comparingFaces = false;  // For showing the comparison progress
  File? _imageFile; // For storing the selected image
  final picker = ImagePicker(); // For picking images
  final List<Map<String, dynamic>> _cards = [
    {
      'title': 'Purchase',
      'color': const Color.fromARGB(255, 1, 1, 1),
      'description': 'Keep track of available inventory and supplies.',
      'image': 'asset/purchase.jpg',
      'page': null, // Navigation target
    },
    {
      'title': 'Outlet',
      'color': const Color.fromARGB(255, 4, 4, 4),
      'description': 'Find and Analyse the Ration Outlets.',
      'image': 'asset/outlet.jpg',
      'page': UserOutlet(), // Navigation target
    },
    {
      'title': 'Card',
      'color': const Color.fromARGB(255, 5, 5, 5),
      'description': 'Manage Ration-Card related operations.',
      'image': 'asset/card.jpg',
      'page': UserCard(), // Navigation target
    },
    {
      'title': 'Notification',
      'color': const Color.fromARGB(255, 9, 9, 9),
      'description': 'New Updations and Notifications are here.',
      'image': 'asset/notification.jpg',
      'page': NotificationsPage(), // Navigation target
    },
    {
      'title': 'Feedback',
      'color': const Color.fromARGB(255, 3, 3, 3),
      'description': 'Give Feedbacks about App and Other Services.',
      'image': 'asset/enquiry.jpg',
      'page': FeedbackPage(), // Handle separately
    },
  ];

  String _userId = '';
   // To hold the user_id from the user profile

  @override
  void initState() {
    super.initState();
    _fetchUserId();

    _pageController.addListener(() {
      // Detect the first or last page and jump to the opposite end
      if (_pageController.position.pixels <= 0) {
        _pageController.jumpToPage(_cards.length - 1); // Jump to last card
      } else if (_pageController.position.pixels >=
          _pageController.position.maxScrollExtent) {
        _pageController.jumpToPage(0); // Jump to first card
      }
    });
  }

  
  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('card_no')!; // Assuming 'card_no' is stored in SharedPreferences
  }

  // Handle the card tap event and navigate accordingly
 
  // Navigate to user profile page
  void gotoprofile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfile()),
    );
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
      request.fields['api_key'] = 'iQmi-6CZt09JXAkCEU-o1mEDbjgcSPUt';
      request.fields['api_secret'] = 'kQHG1Uu7gbCuledKsGSFDgzUrj4BzpjV';
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
          .where('card_no', isEqualTo: _userId)
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

  Future<bool> _compareFaces(String? faceToken, String storedFaceToken) async {
    if (faceToken == null) {
      return false; // Return false if the face token is null
    }

    setState(() {
      comparingFaces = true; // Show the comparison progress indicator
    });

    try {
      var uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
      var request = http.MultipartRequest('POST', uri);
      request.fields['api_key'] = 'iQmi-6CZt09JXAkCEU-o1mEDbjgcSPUt'; // Your Face++ API key
      request.fields['api_secret'] = 'kQHG1Uu7gbCuledKsGSFDgzUrj4BzpjV'; // Your Face++ API secret
      request.fields['face_token1'] = faceToken;  // The token of the captured face
      request.fields['face_token2'] = storedFaceToken;  // The stored token from Firestore

      var response = await request.send();
      if (response.statusCode == 200) {
        var responseBody = await http.Response.fromStream(response);
        var responseData = json.decode(responseBody.body);
        double confidence = responseData['confidence'];  // Similarity score

        // Step 6: If confidence is high (you can adjust the threshold)
        if (confidence > 80.0) {
          setState(() {
            comparingFaces = false; // Hide the comparison progress indicator
          });
          return true; // Faces match
        } else {
          setState(() {
            comparingFaces = false; // Hide the comparison progress indicator
          });
          return false; // Faces don't match
        }
      } else {
        setState(() {
          comparingFaces = false; // Hide the comparison progress indicator
        });
        return false; // Return false if the comparison fails
      }
    } catch (e) {
      setState(() {
        comparingFaces = false; // Hide the comparison progress indicator
      });
      print(e);
      return false; // Return false if there's an error with Face++ comparison API
    }
  }
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

  void _onCardTapped(BuildContext context, Widget? page) async {
  if (page != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  } else {
    await purchase(); // Call the purchase method when "Purchase" card is tapped
  }
}

Future<void> purchase() async {
  setState(() {
    loading = true;
  });
  try {

     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please capture your face to proceed."))
      );

    // Step 1: Capture the face image
    await _pickImage();
    if (_imageFile == null) {
      setState(() {
        loading = false;
      });
      return; // Exit if no image is captured
    }
    _showDialog("Processing", "Face Verification in Progress do not click go back or click to the Purchase");

    
    // Step 2: Upload the image and detect the face concurrently with other checks
    String? faceToken = await _uploadImageToFacePlusPlus();
    if (faceToken == null) {
      setState(() {
        loading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No face detected. Please try again.")));
    _showDialog("Unsuccessful", "No face detected. Please try again.");

      return;
    }

    // Step 3: Retrieve the stored face token from Firestore
    QuerySnapshot cardSnapshot = await FirebaseFirestore.instance
        .collection('Card')
        .where('card_no', isEqualTo: _userId)
        .limit(1)
        .get();

    if (cardSnapshot.docs.isEmpty) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Card number not found.")));
      return;
    }

    // Step 4: Get the stored face token from Firestore
    String storedFaceToken = cardSnapshot.docs.first['face_token'];

    // Step 5: Compare the captured face token with the stored one
    bool isFaceMatched = await _compareFaces(faceToken, storedFaceToken);

    if (!isFaceMatched) {
      setState(() {
        loading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Face does not match.")));
    _showDialog("Unsuccessful", "Face doesn't match. Please try again.");

      return;
    }

    // Step 6: If face matches, proceed to the purchase page
    setState(() {
      loading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Face verified! Proceeding to purchase...")));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserPurchase(), // Navigate to the UserPurchase page
      ),
    );
  } catch (e) {
    setState(() {
      loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred. Please try again.")));
  }
}

  // Handle the back button press to close the app
  Future<bool> _onWillPop() async {
    // Close the app when the back button is pressed
    SystemNavigator.pop();
    return false; // Prevent the default back navigation behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Custom back button behavior
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black, // Black background for the app bar
          automaticallyImplyLeading: false, // Remove default back button
          title: Row(
            children: [
              // Logo on the left
              ClipOval(
                child: Image.asset(
                  'asset/logo.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 10),
              // Spacer to center the text
              Spacer(),
              // Centered "E-Ration" text
              Text(
                'E-Ration', // Change header text to "E-Ration"
                style: GoogleFonts.merriweather(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26.0, // Adjusted font size for app bar
                ),
              ),
              Spacer(),
              // Profile icon on the right
              IconButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color.fromARGB(255, 255, 255, 254),
                  child: Icon(Icons.person, color: const Color.fromARGB(255, 8, 8, 8)),
                ),
                onPressed: gotoprofile,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 255, 255, 255),
                    const Color.fromARGB(255, 248, 247, 245),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                // Cards Section with PageView.builder
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: null, // Infinite pages
                    itemBuilder: (context, index) {
                      final card = _cards[index % _cards.length]; // Looping
                      return _buildPageCard(context, card);
                    },
                  ),
                ),
                // Dot indicator (SmoothPageIndicator)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SmoothPageIndicator(
                    controller: _pageController, // Controller to sync with PageView
                    count: _cards.length, // Number of dots
                    effect: ExpandingDotsEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: const Color.fromARGB(255, 6, 6, 6), // Active dot color
                      dotColor: Colors.white.withOpacity(0.5), // Inactive dot color
                    ),
                  ),
                ),
              ],
            ),
            // Floating Chatbot Icon Button at the bottom-right
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AiChatPage()), // Navigate to the Chatbot page
                  );
                },
                child: Icon(Icons.chat, color: Colors.white), // Chatbot icon
                backgroundColor: Colors.black, // Set the background color for the button
              ),
            ),
            // Circular progress indicator when faces are being compared
          
          ],
        ),
      ),
    );
  }

  // Card UI for each PageView item
  Widget _buildPageCard(BuildContext context, Map<String, dynamic> card) {
    return Center(
      child: GestureDetector(
        onTap: () => _onCardTapped(context, card['page']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: card['color'].withOpacity(0.4),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  card['image'],
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(height: 20),
                  Text(
                    card['title'],
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 250, 248, 248),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      card['description'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 