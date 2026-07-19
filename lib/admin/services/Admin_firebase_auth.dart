import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/admin/screens/admin_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth_Services {
  final firebaseAuth = FirebaseAuth.instance;
  final firebaseDatabase = FirebaseFirestore.instance;

  // Admin login method
  Future<void> Admin_Login({
    required String email,
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
        // Successfully signed in, now fetch the user's data from Firestore
        final userDoc = await firebaseDatabase.collection('Admin').doc(user.user?.uid).get();

        if (userDoc.exists) {
          final userData = userDoc.data();

          // You can handle further data retrieval here if needed, for example:
          // final adminName = userData?['name'];

          // Navigate to the admin home screen (or whichever screen you'd like)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return AdminHomeScreen(); // Change this to your desired screen
              },
            ),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful')),
          );
        } else {
          // User data not found in Firestore
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data not found in database')),
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
