import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications",style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 4, 4, 4),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 255, 255, 255),],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('Notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No Notifications'));
            }

            var notifications = snapshot.data!.docs;

            return ListView.builder(
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
      margin: EdgeInsets.all(10),
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
                color: const Color.fromARGB(255, 77, 75, 75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
