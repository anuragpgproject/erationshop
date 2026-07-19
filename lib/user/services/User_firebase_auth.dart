
import 'package:erationshop/user/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/user/screens/uhome_screen.dart';



class Auth_Services
{
  final firebaseAuth= FirebaseAuth.instance;
  final firebaseDatabase = FirebaseFirestore.instance;
  Future<void> User_Register({required String name, required String cardno,required String email, required String password,required BuildContext context} )
   async {
    try{
      final user =await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      print(user.user?.uid);
      await firebaseDatabase.collection('User').doc(user.user?.uid).set({
        'card_no':cardno,
        'email':email,
        'name':name
        
      })   ; 
       Navigator.push(context, MaterialPageRoute(
        builder: (context) {
          return Login_Screen();
        },
      ));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('registration Successfull')));
    }
    catch (e) {
  print('Error during registration: $e'); // Log the error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Registration Failed: $e'))
  );
  }
   }
   Future<void> User_Login({
  required String email,
  required String password,
  required String cardno,
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
      final userDoc = await firebaseDatabase.collection('User').doc(user.user?.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final storedCardNo = userData?['card_no'];

        // Check if the stored card number matches the provided card number
        if (storedCardNo == cardno) {
          // Proceed with the user data, for example:
          print('Logged in user with card number: $storedCardNo');

          // Navigate to the home screen (or whichever screen you'd like)
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) {
              return UhomeScreen(); // Change this to your desired screen
            },
          ));

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login Successful')),
          );
        } else {
          // Card number mismatch
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card number does not match')),
          );
        }
      } else {
        // User data does not exist in Firestore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found in database')),
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