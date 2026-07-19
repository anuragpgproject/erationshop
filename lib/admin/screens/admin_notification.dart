import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  _AdminNotificationPageState createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  // Controllers for text fields
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add notification to Firestore
  Future<void> addNotification() async {
    if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
      try {
        // Add notification data to Firestore 'Notifications' collection
        await _firestore.collection('Notifications').add({
          'title': titleController.text,
          'content': contentController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Send push notification to all users
        await sendPushNotificationToAllUsers(titleController.text, contentController.text);

        // Clear the text fields after posting
        titleController.clear();
        contentController.clear();
      } catch (e) {
        // Show error if there is an issue with the Firestore operation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post notification: $e')),
        );
      }
    } else {
      // Show a simple validation error message if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content')),
      );
    }
  }

  // Function to send push notifications to all users (no need for player_id)
  Future<void> sendPushNotificationToAllUsers(String title, String content) async {
    try {
      // Prepare the message for sending to all users
      var message = {
        "app_id": "bde1b039-f0cc-41a7-b483-9203d4b15c0e",  // Replace with your OneSignal App ID
        "headings": {"en": title},
        "contents": {"en": content},
        // This sends the notification to all users
        "included_segments": ["All"],  // Targets all users subscribed to notifications
      };

      // Send the notification
      await sendNotificationToOneSignal(message);
      print("Notification sent to all users.");
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  // Function to send the notification using OneSignal API (HTTP request)
  Future<void> sendNotificationToOneSignal(Map<String, dynamic> message) async {
    final String oneSignalApiUrl = 'https://onesignal.com/api/v1/notifications';
    final String oneSignalRestApiKey = 'os_v2_app_xxq3aopqzra2pnedsib5jmk4bzo5zwrnegpuigms65ckx3hxcb2siedmu6vegz2rboi7n3cmjfbwizxjjjlljeoojq6wlagelcvey2q'; // Replace with your API key

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $oneSignalRestApiKey',
    };

    try {
      final response = await http.post(
        Uri.parse(oneSignalApiUrl),
        headers: headers,
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Function to delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      // Delete the notification from Firestore
      await _firestore.collection('Notifications').doc(notificationId).delete();
    } catch (e) {
      // Show error if there is an issue with the Firestore operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Notification',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // Applying a gradient to the entire page background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 253, 253, 253),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Input field for notification title
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Notification Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Input field for notification content
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Notification Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4, // Allow multiple lines for content
              ),
              const SizedBox(height: 16),
              // Button to post the notification
              ElevatedButton(
                onPressed: addNotification,
                child: const Text(
                  'Post Notification',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 32),
              // Display list of posted notifications
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Notifications')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading notifications.'));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No notifications yet.'));
                    }

                    final notifications = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        final notificationId = notification.id; // Get the notification ID
                        final title = notification['title'] ?? 'No Title';
                        final content = notification['content'] ?? 'No Content';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(title),
                            subtitle: Text(content),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                // Confirm before deleting
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Notification'),
                                      content: const Text('Are you sure you want to delete this notification?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await deleteNotification(notificationId);
                                            Navigator.pop(context); // Close the dialog
                                          },
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
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
      ),
    );
  }
}
