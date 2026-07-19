import 'dart:math';
import 'package:erationshop/user/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _cardNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool isVerificationStep = false;
  String verificationCode = "";
  bool isPasswordChanged = false;

  // Step 1: Submit Card Number and Email
 Future<void> submitCardAndEmail() async {
  final email = _emailController.text.trim();
  final cardNo = _cardNoController.text.trim();





  bool isValidAdmin = await checkUserExists(cardNo,email);  // Ensure this completes before continuing

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
  // Step 2: Check if the User Exists in Firebase
  Future<bool> checkUserExists(String cardNo, String email) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('User')
        .where('card_no', isEqualTo: cardNo)
        .where('email', isEqualTo: email)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Step 3: Generate Verification Code
  String generateVerificationCode() {
    final random = Random();
    final code = (random.nextInt(900000) + 100000).toString(); // 6-digit code
    return code;
  }

  // Step 4: Send Verification Email using SendGrid SMTP
  Future<void> sendVerificationEmail(String email, String code) async {
    final smtpServer = SmtpServer(
      'smtp.sendgrid.net', // SendGrid SMTP server
      username: 'apikey',  // Use "apikey" as the username
      password: dotenv.env['SENDGRID_API_KEY'],  // Your SendGrid API key here
      port: 587,           // TLS connection (587 recommended)
      ssl: false,          // False because we use TLS, not SSL
    );

    final message = Message()
      ..from = Address('erationprojectmgc@gmail.com', 'E-RATION')  // Sender's email
      ..recipients.add(email)  // Recipient's email
      ..subject = 'Your Password Reset Code'
      ..text = 'Your verification code is: $code';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ${sendReport.toString()}');
    } on MailerException catch (e) {
      print('Message not sent. ${e.toString()}');
    }
  }

  // Step 5: Handle Verification Code and Password Change
  Future<void> verifyCodeAndChangePassword() async {
    if (_verificationCodeController.text == verificationCode) {
      if (_newPasswordController.text == _confirmPasswordController.text) {
        await updatePassword(_emailController.text, _newPasswordController.text);
        setState(() {
          isPasswordChanged = true;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context){
          return Login_Screen();
        }));
      } else {
        showErrorDialog('Passwords do not match.');
      }
    } else {
      showErrorDialog('Invalid verification code.');
    }
  }

  // Step 6: Update the User Password in Firebase
  Future<void> updatePassword(String email, String newPassword) async {
    var userDoc = await FirebaseFirestore.instance
        .collection('User')
        .where('email', isEqualTo: email)
        .get();

    if (userDoc.docs.isNotEmpty) {
      var user = userDoc.docs.first;
      await FirebaseFirestore.instance
          .collection('User')
          .doc(user.id)
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
      appBar: AppBar(
        title: Text(
          'Forgot Password ?',
          style: TextStyle(color: Colors.white), // Change text color to white
        ),
        backgroundColor: Colors.black, // Set AppBar background color to black
        iconTheme: IconThemeData(color: Colors.white), // Set back icon color to white
      ),
      body: Container(
        color: Colors.white, // Set the background color of the page to white
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
                    'Enter Following Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _cardNoController,
                    decoration: InputDecoration(
                      labelText: 'Card Number',
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
                    onPressed: submitCardAndEmail,
                    child: Text('    Submit    '),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 236, 238, 213),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
