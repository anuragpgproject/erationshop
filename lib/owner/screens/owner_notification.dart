import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OwnerNotification extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 2, 2, 2),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        // Gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
                  const Color.fromARGB(255, 255, 255, 255),
                  const Color.fromARGB(255, 255, 255, 255)// Gradient color 2 (yellowish)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Notifications')
              .orderBy('timestamp', descending: true)  // Order by timestamp descending
              .snapshots(),
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // No data state
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No Notifications'));
            }

            // Getting the list of notifications
            var notifications = snapshot.data!.docs;

            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notification = notifications[index];
                return NotificationCard(
                  title: notification['title'],
                  content: notification['content'],
                  timestamp: notification['timestamp'],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String content;
  final Timestamp timestamp;

  NotificationCard({
    required this.title,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = timestamp.toDate();
    String formattedDate =
        "${dateTime.day} ${dateTime.month} ${dateTime.year} at ${dateTime.hour}:${dateTime.minute}:${dateTime.second} UTC";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(content),
            SizedBox(height: 8),
            Text(
              "Time: $formattedDate",
              style: TextStyle(
                fontSize: 12,
                color: const Color.fromARGB(255, 102, 101, 101),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
