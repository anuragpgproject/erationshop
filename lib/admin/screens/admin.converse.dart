import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const ConversePage(),
    );
  }
}

class ConversePage extends StatelessWidget {
  const ConversePage({super.key});

  // Fetch messages from Firestore
  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'content': doc['content'] ?? 'No content provided',
        'status': doc['status'] ?? 'No status provided',
        'timestamp': doc['timestamp'],
        'reply': doc['reply'] ?? '',
        'messageId': doc.id, // Adding the document ID for reference
        'shopId': doc['shop_id'], // Adding shopId for reference
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Enquiries',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
                  const Color.fromARGB(255, 255, 255, 255),
                  const Color.fromARGB(255, 255, 255, 255),],
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchMessages(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error fetching messages'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No messages available'));
            } else {
              final messages = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: message['reply'].isEmpty
                          ? Icon(
                              Icons.report_problem,
                              color: Colors.redAccent,
                            )
                          : Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                      title: Text(
                        message['content'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${message['status']}'),
                          const SizedBox(height: 5),
                          Text(
                            'Filed on: ${message['timestamp']?.toDate().toString() ?? 'No timestamp available'}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          if (message['reply'].isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Reply: ${message['reply']}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.green),
                              ),
                            ),
                          // Display Shop ID
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Shop ID: ${message['shopId']}',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageDetailsPage(
                              message: message,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class MessageDetailsPage extends StatefulWidget {
  final Map<String, dynamic> message;

  const MessageDetailsPage({required this.message, super.key});

  @override
  _MessageDetailsPageState createState() => _MessageDetailsPageState();
}

class _MessageDetailsPageState extends State<MessageDetailsPage> {
  final TextEditingController _replyController = TextEditingController();
  bool isReplied = false;

  @override
  void initState() {
    super.initState();
    // Check if the message already has a reply
    isReplied = widget.message['reply'].isNotEmpty;
  }

  // Submit the reply and update the message status to 'Resolved'
  Future<void> _submitReply() async {
    if (_replyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply before submitting')),
      );
      return;
    }

    try {
      // Get the document reference for the current message
      final messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.message['messageId']);

      // Update the document with the reply and set the status to 'Resolved'
      await messageRef.update({
        'reply': _replyController.text,
        'responseTimestamp': FieldValue.serverTimestamp(),
        'status': 'Resolved', // Changing the status to 'Resolved'
      });

      setState(() {
        isReplied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reply submitted successfully')),
      );

      // Optionally, clear the text field after submission
      _replyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting reply')),
      );
    }
  }

  // Delete the message from Firestore
  Future<void> _deleteMessage() async {
    try {
      final messageRef = FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.message['messageId']);

      // Delete the message document
      await messageRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );

      // Navigate back to the previous page
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
                  const Color.fromARGB(255, 255, 255, 255),
                  const Color.fromARGB(255, 255, 255, 255),],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enquiry',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Content: ${widget.message['content']}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Status: ${widget.message['status']}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Reply:',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (widget.message['reply'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    widget.message['reply']!,
                    style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.green),
                  ),
                )
              else
                const Text('No reply yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 20),
              Text(
                'Filed on: ${widget.message['timestamp']?.toDate().toString() ?? 'No timestamp available'}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                'Shop ID: ${widget.message['shopId']}',
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              if (!isReplied)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submit Reply:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.black),
                    ),
                    TextField(
                      controller: _replyController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Enter your reply here...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _submitReply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 22, 170, 42),
                        ),
                        child: const Text('Submit Reply',style: TextStyle(color: Colors.black),),
                      ),
                    ),
                  ],
                ),
                
                Center(child: 
              ElevatedButton(
                onPressed: _deleteMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text('Delete Message',style: TextStyle(color: Colors.black),),
              ),)
            ],
          ),
        ),
      ),
    );
  }
}
