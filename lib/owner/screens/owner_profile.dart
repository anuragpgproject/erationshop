import 'package:erationshop/intro/screens/firstscreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required String shopId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String shopId = '';
  Map<String, dynamic>? ownerData;
  TextEditingController _newPasswordController = TextEditingController();
  bool _isPasswordChanging = false;

  @override
  void initState() {
    super.initState();
    _getShopId();
  }

  // Retrieve shop_id from SharedPreferences
  void _getShopId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      shopId = prefs.getString('shop_id') ?? '';
    });

    if (shopId.isNotEmpty) {
      _fetchOwnerData(shopId);
    }
  }

  // Fetch owner data from Firestore using the shop_id
  void _fetchOwnerData(String shopId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Shop Owner')
          .where('shop_id', isEqualTo: shopId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          ownerData = querySnapshot.docs.first.data();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('No owner found with the provided shop ID.')));
      }
    } catch (e) {
      print('Error fetching owner data: $e');
    }
  }

  // Method to update password in Firestore
  void _updatePassword(String newPassword) async {
    if (newPassword.isNotEmpty) {
      try {
        // Check if the document exists before updating
        final docSnapshot = await FirebaseFirestore.instance
            .collection('Shop Owner')
            .where('shop_id', isEqualTo: shopId)
            .get();

        if (docSnapshot.docs.isNotEmpty) {
          final docRef = docSnapshot.docs.first.reference;

          // Update the password field
          await docRef.update({'password': newPassword});

          // Clear the text field and hide the form
          _newPasswordController.clear();
          setState(() {
            _isPasswordChanging = false;
          });

          // Show a success message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Password updated successfully!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Shop ID does not exist in Firestore.')));
        }
      } catch (e) {
        print('Error updating password: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update password')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password cannot be empty')));
    }
  }

  // Method to handle logout
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('shop_id');  // Remove the stored shop_id
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => IntroPage()),  // Navigate to IntroPage
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.merriweather(fontWeight: FontWeight.bold,color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,  // Call the logout method when pressed
          ),
        ],
      ),
      body: ownerData == null
          ? Center(child: CircularProgressIndicator())
          : Container( // Container holding the gradient background
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 255, 254, 253),
                    const Color.fromARGB(255, 255, 255, 255),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column( // Column wrapping the content
                children: [
                  Expanded( // Ensures the content takes up all available space
                    child: SingleChildScrollView( // Allows scrolling when content overflows
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture from assets
                            Center(
                              child: ClipOval(
                                child: Image.asset(
                                  'asset/profilepic.jpg', // Replace with your image path
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Displaying profile data in a box format
                            _buildInfoBox('Name', ownerData!['name']),
                            _buildInfoBox('Email', ownerData!['email']),
                            _buildInfoBox('Phone', ownerData!['phone']),
                            _buildInfoBox('Shop', ownerData!['store_name']),
                            _buildInfoBox('Address', ownerData!['address']),

                            // Add Change Password Button
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isPasswordChanging = true;
                                });
                              },
                              child: Text('Change Password',style: TextStyle(color: Colors.black),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 175, 174, 173),
                              ),
                            ),

                            // If _isPasswordChanging is true, show the password change form
                            if (_isPasswordChanging) ...[
                              SizedBox(height: 20),
                              _buildPasswordChangeForm(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Method to build a standard box for displaying information
  Widget _buildInfoBox(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(66, 101, 99, 99),
              
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$title:',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the password change form
  Widget _buildPasswordChangeForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _newPasswordController,
          obscureText: true, // Hide the password input
          decoration: InputDecoration(
            hintText: 'Enter new password',
            hintStyle: TextStyle(color: const Color.fromARGB(255, 53, 52, 52)),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            fillColor: const Color.fromARGB(255, 180, 177, 175),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            _updatePassword(_newPasswordController.text);
          },
          child: Text('Submit',style: TextStyle(color: Colors.black),),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 180, 177, 175),
          ),
        ),
      ],
    );
  }
}
