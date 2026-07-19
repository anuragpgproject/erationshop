import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/owner/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth_Services{
  final firebaseAuth= FirebaseAuth.instance;
  final firebaseDatabase = FirebaseFirestore.instance;

  Future<void> Owner_Login({
  required String email,
  required String shopid,
  required String password,
  required BuildContext context,
}) async {
  try {
    // Attempt to log in with email and password
    final user = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (user.user != null) {
      // Successfully signed in, now fetch the user's card number from Firestore
      final userDoc = await firebaseDatabase.collection('Shop Owner').doc(user.user?.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final storedShopid = userData?['shop_id'];

        // Check if the stored card number matches the provided card number
        if (storedShopid == shopid) {
          // Proceed with the user data, for example:
          print('Logged in user with Shop id: $storedShopid');

          // Navigate to the home screen (or whichever screen you'd like)
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) {
              return OwnerHomeScreen(); // Change this to your desired screen
            },
          ));

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful')),
          );
        } else {
          // Shop number mismatch
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop Id does not match')),
          );
        }
      } else {
        // User data does not exist in Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(' data not found in database')),
        );
      }
    }
  } catch (e) {
    // Handle login error
    print('Error during login: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login Failed: $e')),
    );
  }
}


   
}
