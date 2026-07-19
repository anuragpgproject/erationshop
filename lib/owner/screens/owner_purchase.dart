import 'dart:convert';
import 'package:erationshop/user/screens/user_purchase.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class OwnerPurchase extends StatefulWidget {
  @override
  _OwnerPurchaseState createState() => _OwnerPurchaseState();
}

class _OwnerPurchaseState extends State<OwnerPurchase> {
  final TextEditingController _cardNoController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isVerifying = false;
  String? mobileNo;
  String? cardNo;

  // Function to verify the card number and send OTP
  Future<void> _verifyCardAndSendOTP() async {
    setState(() {
      _isSubmitting = true;
    });

    cardNo = _cardNoController.text;

    if (cardNo != null && cardNo!.isNotEmpty) {
      // Fetch the card document from Firestore
      var cardDoc = await FirebaseFirestore.instance
          .collection('Card')
          .where('card_no', isEqualTo: cardNo)
          .limit(1)
          .get();

      if (cardDoc.docs.isEmpty) {
        // If no card found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Card number not found')),
        );
        setState(() {
          _isSubmitting = false;
        });
      } else {
        // Card found, get the mobile number
        mobileNo = cardDoc.docs[0]['mobile_no'];

        // Send OTP using Twilio Verify API
        await _sendOTPViaTwilio(mobileNo!);

        // Save the card number to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('card_no', cardNo!);

        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid card number')),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Function to send OTP via Twilio Verify API
  Future<void> _sendOTPViaTwilio(String mobileNo) async {
    // Twilio credentials (replace with your actual credentials)
    final String? accountSid = dotenv.env['accountSid'];  // Your Twilio Account SID
    final String? authToken = dotenv.env['authToken'];  // Your Twilio Auth Token
    final String? serviceSid = dotenv.env['serviceSid'];  // Your Twilio Verify Service SID

    // Twilio Verify API URL for sending OTP
    final String url = 'https://verify.twilio.com/v2/Services/$serviceSid/Verifications';

    // Prepare the payload
    final Map<String, String> data = {
      'To': mobileNo,
      'Channel': 'sms',  // Use 'sms' to send via SMS
    };

    // Send the POST request
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
      },
      body: data,
    );

    if (response.statusCode == 201) {
      print('OTP sent successfully');
    } else {
      print('Failed to send OTP: ${response.body}');
    }
  }

  // Function to verify OTP
  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
    });

    String otp = _otpController.text;

    // Twilio credentials (replace with your actual credentials)
    final String? accountSid = dotenv.env['accountSid'];  // Your Twilio Account SID
    final String? authToken = dotenv.env['2authToken'];    // Your Twilio Auth Token
    final String? serviceSid = dotenv.env['2serviceSid'];  // Your Twilio Verify Service SID

    // Twilio API URL for verifying OTP
    final String url = 'https://verify.twilio.com/v2/Services/$serviceSid/VerificationCheck';

    // Prepare the payload
    final Map<String, String> data = {
      'To': mobileNo!,
      'Code': otp,
    };

    // Send the POST request to verify the OTP
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
      },
      body: data,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP Verified Successfully')),
      );

      // Navigate to the next screen (for example, UserPurchase)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserPurchase(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }

    setState(() {
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Purchase', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Card Number Input
            if (mobileNo == null) ...[
              Text(
                'Enter Card Number',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _cardNoController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color.fromARGB(255, 180, 177, 175),
                  labelText: 'Card Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _verifyCardAndSendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 180, 177, 175),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Submit', style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ],
            // OTP Verification
            if (mobileNo != null) ...[
              Text('Enter the OTP sent to your mobile number'),
              SizedBox(height: 20),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isVerifying ? null : _verifyOTP,
                child: _isVerifying
                    ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Verify OTP'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
