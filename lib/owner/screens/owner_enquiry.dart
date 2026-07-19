import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EnquiryPage extends StatefulWidget {
  final String shopId; // Passed shopId to the page

  EnquiryPage({required this.shopId});

  @override
  _EnquiryPageState createState() => _EnquiryPageState();
}

class _EnquiryPageState extends State<EnquiryPage> {
  final TextEditingController _messageController = TextEditingController();
  late Stream<QuerySnapshot> _enquiriesStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream to fetch enquiries for the given shop_id
    _enquiriesStream = FirebaseFirestore.instance
        .collection('messages')
        .where('shop_id', isEqualTo: widget.shopId) // Query based on shop_id
        .orderBy('timestamp', descending: true) // Optional: Order by timestamp
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enquiry Form',style: TextStyle(color: Colors.white,)),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white), // AppBar color
        elevation: 4, // Subtle shadow for the AppBar
      ),
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 251, 251, 251), // Gradient color 1
              Color.fromARGB(255, 255, 255, 255), // Gradient color 2
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Input Field for Message
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Your Enquiry',
                labelStyle: TextStyle(color: const Color.fromARGB(255, 6, 6, 6)),
                hintText: 'Enter your question or enquiry here...',
                hintStyle: TextStyle(color: const Color.fromARGB(255, 4, 4, 4).withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 5,
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 20),
            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 187, 185, 183), // Button color
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                shadowColor: Colors.blueAccent.withOpacity(0.4), // Button shadow
              ),
              onPressed: () async {
                String content = _messageController.text.trim();

                if (content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a message!")),
                  );
                  return;
                }

                // Submit the enquiry to Firestore with shopId
                try {
                  await FirebaseFirestore.instance.collection('messages').add({
                    'content': content,
                    'timestamp': FieldValue.serverTimestamp(),
                    'shop_id': widget.shopId, // Use widget.shopId to access the passed parameter
                    'status': 'pending',
                    'reply': '', // Space for reply
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Enquiry submitted successfully!")),
                  );
                  _messageController.clear(); // Clear the message field after submission
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error submitting enquiry: $e")),
                  );
                }
              },
              child: Text(
                'Submit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 30),
            // Submitted Enquiries Section
            Text(
              'Submitted Enquiries:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 9, 9, 9),
              ),
            ),
            SizedBox(height: 10),
            // Display enquiries in a ListView
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _enquiriesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No enquiries found."));
                  }

                  // Get the list of enquiries documents
                  final enquiries = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: enquiries.length,
                    itemBuilder: (context, index) {
                      final enquiry = enquiries[index];
                      final content = enquiry['content'];
                      final timestamp = enquiry['timestamp']?.toDate();
                      final status = enquiry['status'];
                      final reply = enquiry['reply'];

                      return Card(
                        elevation: 4, // Card shadow
                        margin: EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            content,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time: ${timestamp != null ? timestamp.toString() : 'N/A'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Status: $status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: status == 'pending' ? Colors.orange : Colors.green,
                                ),
                              ),
                              if (reply.isNotEmpty) ...[
                                SizedBox(height: 5),
                                Text(
                                  'Reply: $reply',
                                  style: TextStyle(fontSize: 14, color: Colors.blue),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
