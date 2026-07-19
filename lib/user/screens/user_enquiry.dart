import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserEnquiry extends StatefulWidget {
  final String user_id; // card_no will be passed instead of user_id

  const UserEnquiry({super.key, required this.user_id});

  @override
  _UserEnquiryState createState() => _UserEnquiryState();
}

class _UserEnquiryState extends State<UserEnquiry> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, String>> _enquiries = [];
  bool _isLoading = true;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Print the user ID (for debugging purposes)
    print("User ID in initState: ${widget.user_id}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch the enquiries when the widget is initialized
    print("didChangeDependencies called. User ID: ${widget.user_id}");
    _fetchEnquiries();
  }

  // Fetch enquiries
  Future<void> _fetchEnquiries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the enquiries using the user_id (from the Enquiries collection)
      QuerySnapshot querySnapshot = await _firestore
          .collection('Enquiries')
          .where('card_no', isEqualTo: widget.user_id)
          .orderBy('timestamp', descending: true) // Ensure timestamp is indexed
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _enquiries = [];
          _isLoading = false;
        });
        return;
      }

      // Process the documents
      setState(() {
        _enquiries = querySnapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>; // Firestore document data as dynamic

          return {
            'subject': data['subject']?.toString() ?? 'No Subject', // Explicit conversion to string
            'description': data['description']?.toString() ?? 'No Description', // Explicit conversion to string
            'status': data['status']?.toString() ?? 'No Status', // Explicit conversion to string
            'response': data['response']?.toString() ?? 'No Response', // Explicit conversion to string
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching enquiries: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching enquiries. Please try again later.')),
      );
    }
  }

  // Method to handle submission of enquiries
  void _submitEnquiry() async {
    String subjectText = _subjectController.text.trim();
    String descriptionText = _descriptionController.text.trim();

    if (subjectText.isNotEmpty && descriptionText.isNotEmpty) {
      try {
        await _firestore.collection('Enquiries').add({
          'subject': subjectText,
          'description': descriptionText,
          'status': 'Submitted',
          'timestamp': FieldValue.serverTimestamp(),
          'response': null,
          'card_no': widget.user_id, // Store the user_id here
        });

        _subjectController.clear();
        _descriptionController.clear();
        _fetchEnquiries();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Your enquiry has been submitted.')),
        );
      } catch (e) {
        print('Error submitting enquiry: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting enquiry. Please try again later.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter both subject and description.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Enquiry',style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity, // Ensure the container takes up full screen height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            Color.fromARGB(255, 254, 254, 254),
            Color.fromARGB(255, 255, 255, 255),],
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildEnquiryForm(),
                    SizedBox(height: 20),
                    _buildEnquiryList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEnquiryForm() {
    return Card(
      color: const Color.fromARGB(255, 196, 192, 192).withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Your Enquiry or Complaint',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Enter the subject (title) of your enquiry...',
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the detailed description of your enquiry...',
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitEnquiry,
              child: Text(
                'Submit Enquiry',
                style: TextStyle(fontSize: 18,color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryList() {
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Submitted Enquiries:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if (_enquiries.isEmpty) Text('No enquiries submitted yet.'),
            for (int i = 0; i < _enquiries.length; i++) _buildEnquiryItem(i),
          ],
        ),
      ),
    );
  }

  Widget _buildEnquiryItem(int index) {
    String status = _enquiries[index]['status']!;
    String response = _enquiries[index]['response']!;

    Color statusColor = status == 'Resolved' ? Colors.green : Colors.red;
    Color responseColor = status == 'Resolved' ? Colors.green : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _enquiries[index]['subject']!,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    _enquiries[index]['description']!,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Status: $status',
                    style: TextStyle(fontSize: 14, color: statusColor),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Response: $response',
                    style: TextStyle(fontSize: 14, color: responseColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
