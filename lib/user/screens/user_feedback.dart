import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _appFeedbackController = TextEditingController();
  final TextEditingController _productFeedbackController = TextEditingController();
  bool _isSubmitting = false;

  // Your PythonAnywhere API URL for sentiment analysis
  final String apiUrl = 'https://suraijcv.pythonanywhere.com/analyze'; // Replace with your PythonAnywhere URL

  // Function to get sentiment (positive/negative) using the PythonAnywhere API
  Future<String> _getSentiment(String feedback) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json', // Ensure proper content type for POST request
        },
        body: json.encode({
          'feedback': feedback, // Ensure the key is 'feedback'
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sentiment']; // "positive" or "negative"
      } else {
        print('Error ${response.statusCode}: ${response.body}'); // Debug output
        throw Exception('Failed to get sentiment');
      }
    } catch (e) {
      print('Sentiment Analysis Error: $e');
      throw Exception('Failed to get sentiment');
    }
  }

  // Function to submit feedback to Firestore
  Future<void> _submitFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    String appFeedback = _appFeedbackController.text;
    String productFeedback = _productFeedbackController.text;

    // Check if feedback is empty
    if (appFeedback.isEmpty || productFeedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide feedback for both sections.')));
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      // Get sentiment for both sections
      String appSentiment = await _getSentiment(appFeedback);
      String productSentiment = await _getSentiment(productFeedback);

      print('App Sentiment: $appSentiment, Product Sentiment: $productSentiment'); // Debugging

      // Get the current feedback counts for app feedback
      FirebaseFirestore.instance.collection('UserFeedback').doc('app_feedback').get().then((doc) async {
        if (doc.exists) {
          int positive = doc['positive'];
          int negative = doc['negative'];

          // Update positive/negative count based on sentiment
          if (appSentiment == 'positive') positive++;
          else negative++;

          // Update Firestore with new counts for app feedback
          await FirebaseFirestore.instance.collection('UserFeedback').doc('app_feedback').set({
            'positive': positive,
            'negative': negative,
          });

          print('Updated App Feedback Counts: positive = $positive, negative = $negative'); // Debugging
        } else {
          // If the app_feedback document doesn't exist, create it
          await FirebaseFirestore.instance.collection('UserFeedback').doc('app_feedback').set({
            'positive': appSentiment == 'positive' ? 1 : 0,
            'negative': appSentiment == 'negative' ? 1 : 0,
          });
          print('Created app_feedback document with initial values');
        }
      }).catchError((error) {
        print('Error while fetching or updating Firestore (app_feedback): $error');
      });

      // Get the current feedback counts for product feedback
      FirebaseFirestore.instance.collection('UserFeedback').doc('product_feedback').get().then((doc) async {
        if (doc.exists) {
          int positive = doc['positive'];
          int negative = doc['negative'];

          // Update positive/negative count based on sentiment
          if (productSentiment == 'positive') positive++;
          else negative++;

          // Update Firestore with new counts for product feedback
          await FirebaseFirestore.instance.collection('UserFeedback').doc('product_feedback').set({
            'positive': positive,
            'negative': negative,
          });

          print('Updated Product Feedback Counts: positive = $positive, negative = $negative'); // Debugging
        } else {
          // If the product_feedback document doesn't exist, create it
          await FirebaseFirestore.instance.collection('UserFeedback').doc('product_feedback').set({
            'positive': productSentiment == 'positive' ? 1 : 0,
            'negative': productSentiment == 'negative' ? 1 : 0,
          });
          print('Created product_feedback document with initial values');
        }
      }).catchError((error) {
        print('Error while fetching or updating Firestore (product_feedback): $error');
      });

      // Clear feedback fields
      _appFeedbackController.clear();
      _productFeedbackController.clear();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback submitted successfully')));
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Function to open Gmail for email inquiries
  void _openEmail() async {
    final Uri emailUri = Uri.parse('mailto:erationprojectmgc@gmail.com');
    if (await canLaunch(emailUri.toString())) {
      await launch(emailUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open email client')));
    }
  }

  // Function to initiate a phone call with a dummy number
  void _openPhoneCall() async {
    final String phoneNumber = 'tel:+1234567890'; // Dummy phone number
    if (await canLaunch(phoneNumber)) {
      await launch(phoneNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not initiate a phone call')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Feedback', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We value your feedback! Please let us know your thoughts.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _appFeedbackController,
                      decoration: InputDecoration(
                        labelText: 'Feedback about the App',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        hintText: 'Write your feedback here...',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _productFeedbackController,
                      decoration: InputDecoration(
                        labelText: 'Feedback about the Products and Services in Ration Shop',
                        labelStyle: TextStyle(color: Colors.blue),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        hintText: 'Write your feedback here...',
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 173, 175, 176),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'For more enquiries, contact at:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.email, size: 30, color: Colors.blue),
                      onPressed: _openEmail,
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.phone, size: 30, color: Colors.green),
                      onPressed: _openPhoneCall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
