import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pie_chart/pie_chart.dart';

class FeedbackGraphPage extends StatefulWidget {
  @override
  _FeedbackGraphPageState createState() => _FeedbackGraphPageState();
}

class _FeedbackGraphPageState extends State<FeedbackGraphPage> {
  // Data to display the graphs
  int userAppPositive = 0;
  int userAppNegative = 0;
  int userProductPositive = 0;
  int userProductNegative = 0;

  int ownerAppPositive = 0;
  int ownerAppNegative = 0;

  @override
  void initState() {
    super.initState();
    _fetchFeedbackData();
  }

  // Fetch feedback data from Firestore
  Future<void> _fetchFeedbackData() async {
    try {
      // Get User Feedback data for app_feedback
      DocumentSnapshot userAppFeedbackDoc = await FirebaseFirestore.instance.collection('UserFeedback').doc('app_feedback').get();
      if (userAppFeedbackDoc.exists) {
        setState(() {
          userAppPositive = userAppFeedbackDoc['positive'] ?? 0;
          userAppNegative = userAppFeedbackDoc['negative'] ?? 0;
        });
      }

      // Get User Feedback data for product_feedback
      DocumentSnapshot userProductFeedbackDoc = await FirebaseFirestore.instance.collection('UserFeedback').doc('product_feedback').get();
      if (userProductFeedbackDoc.exists) {
        setState(() {
          userProductPositive = userProductFeedbackDoc['positive'] ?? 0;
          userProductNegative = userProductFeedbackDoc['negative'] ?? 0;
        });
      }

      // Get Owner Feedback data for app_feedback
      DocumentSnapshot ownerAppFeedbackDoc = await FirebaseFirestore.instance.collection('OwnerFeedback').doc('app_feedback').get();
      if (ownerAppFeedbackDoc.exists) {
        setState(() {
          ownerAppPositive = ownerAppFeedbackDoc['positive'] ?? 0;
          ownerAppNegative = ownerAppFeedbackDoc['negative'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching feedback data: $e');
    }
  }

  // Function to calculate percentage
  double calculatePercentage(int positive, int negative) {
    int total = positive + negative;
    if (total == 0) return 0;
    return (positive / total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    double userAppPositivePercentage = calculatePercentage(userAppPositive, userAppNegative);
    double userProductPositivePercentage = calculatePercentage(userProductPositive, userProductNegative);

    double ownerAppPositivePercentage = calculatePercentage(ownerAppPositive, ownerAppNegative);

    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback Overview', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Section Title
              Text(
                'User & Owner Feedback Analysis',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 20),

              // Pie Chart for User Feedback: App
              _buildFeedbackPieChart('User App Feedback', userAppPositivePercentage),
              SizedBox(height: 40),

              // Pie Chart for User Feedback: Product
              _buildFeedbackPieChart('User Product & Service Feedback', userProductPositivePercentage),
              SizedBox(height: 40),

              // Pie Chart for Owner Feedback: App
              _buildFeedbackPieChart('Owner App Feedback', ownerAppPositivePercentage),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build pie chart for feedback
  Widget _buildFeedbackPieChart(String title, double positivePercentage) {
    double negativePercentage = 100 - positivePercentage;  // Negative percentage is the complement

    Map<String, double> dataMap = {
      "Positive": positivePercentage,
      "Negative": negativePercentage,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              // ignore: deprecated_member_use
              BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PieChart(
              dataMap: dataMap,
              colorList: [Colors.green, Colors.red],
              chartValuesOptions: ChartValuesOptions(
                showChartValues: true,
                chartValueBackgroundColor: Colors.transparent,
                chartValueStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              chartRadius: 100, // Radius of the chart
              centerTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
              animationDuration: Duration(milliseconds: 800),
            ),
          ),
        ),
      ],
    );
  }
}
