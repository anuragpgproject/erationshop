import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _appFeedbackController = TextEditingController();
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

    // Check if feedback is empty
    if (appFeedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please provide feedback for the app.')));
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      // Get sentiment for app feedback
      String appSentiment = await _getSentiment(appFeedback);

      print('App Sentiment: $appSentiment'); // Debugging

      // Get the current feedback counts for app feedback
      FirebaseFirestore.instance.collection('OwnerFeedback').doc('app_feedback').get().then((doc) async {
        if (doc.exists) {
          int positive = doc['positive'];
          int negative = doc['negative'];

          // Update positive/negative count based on sentiment
          if (appSentiment == 'positive') positive++;
          else negative++;

          // Update Firestore with new counts for app feedback
          await FirebaseFirestore.instance.collection('OwnerFeedback').doc('app_feedback').set({
            'positive': positive,
            'negative': negative,
          });

          print('Updated App Feedback Counts: positive = $positive, negative = $negative'); // Debugging
        } else {
          // If the app_feedback document doesn't exist, create it
          await FirebaseFirestore.instance.collection('OwnerFeedback').doc('app_feedback').set({
            'positive': appSentiment == 'positive' ? 1 : 0,
            'negative': appSentiment == 'negative' ? 1 : 0,
          });
          print('Created app_feedback document with initial values');
        }
      }).catchError((error) {
        print('Error while fetching or updating Firestore (app_feedback): $error');
      });

      // Clear feedback field
      _appFeedbackController.clear();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Owner Feedback', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
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
                    : Text('Submit Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
