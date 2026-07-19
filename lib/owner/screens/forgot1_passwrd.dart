import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Forgot1_Password extends StatefulWidget {
  const Forgot1_Password({super.key});

  @override
  State<Forgot1_Password> createState() => _Forgot1_PasswordState();
}

class _Forgot1_PasswordState extends State<Forgot1_Password> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isVerificationStep = false;
  String verificationCode = "";

  // Step 1: Submit Shop ID and Email to validate
 Future<void> submitShopIdAndEmail() async {
  final email = _emailController.text.trim();
  final shopId = _shopIdController.text.trim();


  bool isValidAdmin = await checkShopOwnerExists(shopId,email);  // Ensure this completes before continuing

  if (isValidAdmin) {
    verificationCode = generateVerificationCode();
    await sendVerificationEmail(email, verificationCode);  // Ensure email is sent before updating the UI

    setState(() {
      isVerificationStep = true;
    });
  } else {
    showErrorDialog('No matching Shop Owner found for the provided email.');
  }
}

  // Step 2: Check if the Shop ID and Email exist in Firestore
  Future<bool> checkShopOwnerExists(String shopId, String email) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('Shop Owner')
        .where('shop_id', isEqualTo: shopId)
        .where('email', isEqualTo: email)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Step 3: Generate a 6-digit Verification Code
  String generateVerificationCode() {
    final random = Random();
    final code = (random.nextInt(900000) + 100000).toString(); // 6-digit code
    return code;
  }

  // Step 4: Send the Verification Code via Email
  Future<void> sendVerificationEmail(String email, String code) async {
    final smtpServer = SmtpServer(
      'smtp.sendgrid.net',
      username: 'apikey',  // Use "apikey" as the username for SendGrid
      password: dotenv.env['SENDGRID_API_KEY'],  // SendGrid API Key
      port: 587,  // TLS connection
      ssl: false,  // False because we use TLS, not SSL
    );

    final message = Message()
      ..from = Address('erationprojectmgc@gmail.com', 'Shop Support')
      ..recipients.add(email)
      ..subject = 'Your Password Reset Code'
      ..text = 'Your verification code is: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
    }
  }

  // Step 5: Verify the Code and Change the Password
  Future<void> verifyCodeAndChangePassword() async {
    if (_verificationCodeController.text == verificationCode) {
      if (_newPasswordController.text == _confirmPasswordController.text) {
        await updatePassword(_emailController.text, _newPasswordController.text);
        setState(() {
          isVerificationStep = false;
        });
        Navigator.pop(context); // Close the Forgot Password screen
      } else {
        showErrorDialog('Passwords do not match.');
      }
    } else {
      showErrorDialog('Invalid verification code.');
    }
  }

  // Step 6: Update Password in Firestore
  Future<void> updatePassword(String email, String newPassword) async {
    var shopDoc = await FirebaseFirestore.instance
        .collection('Shop Owner')
        .where('email', isEqualTo: email)
        .get();

    if (shopDoc.docs.isNotEmpty) {
      var shop = shopDoc.docs.first;
      await FirebaseFirestore.instance
          .collection('Shop Owner')
          .doc(shop.id)
          .update({'password': newPassword});
    }
  }

  // Step 7: Show Error Dialog
  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Forgot Password',style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
        ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 251, 251, 251),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isVerificationStep
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification Code',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 3, 3, 3)),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _verificationCodeController,
                      decoration: InputDecoration(
                        labelText: 'Enter Verification Code',
                        labelStyle: TextStyle(color: const Color.fromARGB(255, 5, 5, 5)),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Enter New Password',
                        labelStyle: TextStyle(color: const Color.fromARGB(255, 1, 1, 1)),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: const Color.fromARGB(255, 3, 3, 3)),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: verifyCodeAndChangePassword,
                      child: Text('   Change Password   '),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 250, 250, 250),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forgot Password?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _shopIdController,
                      decoration: InputDecoration(
                        labelText: 'Shop ID',
                        labelStyle: TextStyle(color: const Color.fromARGB(255, 10, 10, 10)),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: const Color.fromARGB(255, 27, 26, 26)),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitShopIdAndEmail,
                      child: Text('    Submit    ',style: TextStyle(color: Colors.black),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 236, 238, 213),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
