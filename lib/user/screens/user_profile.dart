import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/intro/screens/firstscreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // Fetch card_no from SharedPreferences (or any persistent storage)
      future: _getCardNo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No card number found.'));
        } else {
          final cardNo = snapshot.data!;

          return Scaffold(
            appBar: AppBar(
              title: Text("User Profile",style: TextStyle(color: Colors.white),),
              backgroundColor: const Color.fromARGB(255, 12, 12, 12),
              iconTheme: IconThemeData(color: Colors.white),
            ),
            body: StreamBuilder(
              // Stream to get the user data from Firestore using the retrieved card_no
              stream: FirebaseFirestore.instance
                  .collection('User')
                  .where('card_no', isEqualTo: cardNo)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                } else if (!userSnapshot.hasData || userSnapshot.data == null) {
                  return Center(child: Text('No user data found.'));
                } else {
                  final userProfile = userSnapshot.data!.docs.first;
                  final String name = userProfile['name'] ?? 'N/A';
                  final String cardId = userProfile['card_id'] ?? '';
                  final String email = userProfile['email'] ?? 'N/A';

                  // Fetch card details using the card_id from the User profile
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Card')
                        .doc(cardId)
                        .snapshots(),
                    builder: (context, cardSnapshot) {
                      if (cardSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (cardSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${cardSnapshot.error}'));
                      } else if (!cardSnapshot.hasData ||
                          cardSnapshot.data == null) {
                        return Center(child: Text('Card data not found.'));
                      } else {
                        final cardData = cardSnapshot.data!;
                        final String cardNumber =
                            cardData['card_no'] ?? '**** **** ****';
                        final String mobileNumber =
                            cardData['mobile_no'] ?? 'N/A';
                        final String ownerName =
                            cardData['owner_name'] ?? 'N/A';
                        final String category = cardData['category'] ?? 'N/A';

                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(255, 255, 255, 255), // Light yellow color
                                const Color.fromARGB(255, 255, 255, 255), // Darker yellow color
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Icon
                                Center(
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        const Color.fromARGB(255, 0, 0, 0),
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Email
                                _buildProfileTextField("Email:", email),
                                SizedBox(height: 20),

                                // Card Number with stars
                                _buildProfileTextField(
                                    "Card Number:", cardNumber),
                                SizedBox(height: 20),

                                // Owner Name
                                _buildProfileTextField(
                                    "Card Owner:", ownerName),
                                SizedBox(height: 20),

                                // Category
                                // Add category or any other data you need
                                
                                // Logout Button
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      // Clear SharedPreferences
                                      SharedPreferences prefs =
                                          await SharedPreferences.getInstance();
                                      prefs.remove('card_no');
                                      prefs.remove('shop_id');
                                      prefs.remove('shop_owner_doc_id');
                                      prefs.remove('email');

                                      // Navigate to IntroScreen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => IntroPage()),
                                      );
                                    },
                                    child: Text("Logout",style: TextStyle(color: Colors.black),),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white24, // Set color
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      textStyle: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          );
        }
      },
    );
  }

  // Custom method to create non-editable profile text fields
  Widget _buildProfileTextField(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          enabled: false, // Make the field non-editable
          style: TextStyle(fontSize: 18, color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Enter $title',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            border: OutlineInputBorder(
              borderSide: BorderSide(
                  width: 2, color: const Color.fromARGB(255, 81, 50, 12)),
              borderRadius: BorderRadius.circular(10),
            ),
            fillColor: const Color.fromARGB(255, 202, 196, 182),
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  // Helper function to get the card_no from SharedPreferences
  Future<String?> _getCardNo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('card_no'); // Assuming 'card_no' is stored in SharedPreferences
  }
}
