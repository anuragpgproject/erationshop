import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserCard extends StatefulWidget {
  const UserCard({super.key});

  @override
  _UserCardState createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  Map<String, dynamic>? cardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCardData();
  }

  Future<void> _loadCardData() async {
    final prefs = await SharedPreferences.getInstance();
    final cardNo = prefs.getString('card_no');

    if (cardNo != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('Card')
            .where('card_no', isEqualTo: cardNo)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            cardData = snapshot.docs.first.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print('Card not found for card number: $cardNo');
        }
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print('Error fetching card data: $e');
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('Card number not found in shared preferences.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ration Card Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // Ensure the container takes up the full screen
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : cardData != null
                ? _buildCardDetails(context)
                : const Center(child: Text('No card data found.')),
      ),
    );
  }

  Widget _buildCardDetails(BuildContext context) {
    return SingleChildScrollView( // Added to handle overflow when content is too long
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              gradient: const LinearGradient(
                colors: [Colors.white, Color.fromARGB(255, 151, 163, 214)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardDetailRow('Card Number:', cardData!['card_no'] ?? "N/A"),
                _buildCardDetailRow('Owner Name:', cardData!['owner_name'] ?? "N/A"),
                _buildCardDetailRow('Category:', cardData!['category'] ?? "N/A"),
                _buildCardDetailRow('Address:', cardData!['address'] ?? "N/A"),
                _buildCardDetailRow('Taluk:', cardData!['taluk'] ?? "N/A"),
                _buildCardDetailRow('Ward No:', cardData!['ward_no'] ?? "N/A"),
                _buildCardDetailRow('House No:', cardData!['house_no'] ?? "N/A"),
                _buildCardDetailRow('Local Body:', cardData!['local_body'] ?? "N/A"),
                _buildCardDetailRow('Electrified:', cardData!['electrified'] ?? "N/A"),
                _buildCardDetailRow('LPG:', cardData!['lpg'] ?? "N/A"),
                _buildCardDetailRow('Members Count:', cardData!['members_count'] ?? "N/A"),
                _buildCardDetailRow('Mobile No:', cardData!['mobile_no'] ?? "N/A"),
                _buildCardDetailRow('Monthly Income:', cardData!['monthly_income'] ?? "N/A"),
                const SizedBox(height: 20),
                Text('Members : ',style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                 // Space before the members table
                _buildMembersTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTable() {
    // Get the list of members from the card data
    List<dynamic> members = cardData?['member_list'] ?? [];
    
    // If there are no members, show a message
    if (members.isEmpty) {
      return const Text('No members found for this card.');
    }

    // Create a list of rows to display member information
    List<Widget> rows = [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Occupation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('UID No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    ];

    // Iterate over the member list and create rows for each member
    for (var member in members) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(member['name'] ?? 'N/A'),
              Text(member['age']?.toString() ?? 'N/A'),
              Text(member['occupation'] ?? 'N/A'),
              Text(_maskUID(member['uid_no'] ?? '')),
            ],
          ),
        ),
      );
    }

    // Return the table with the rows of member data
    return Column(children: rows);
  }

  // Mask UID number to show only last 4 digits
  String _maskUID(String uid) {
    if (uid.length > 4) {
      return '*' * (uid.length - 4) + uid.substring(uid.length - 4);
    } else {
      return uid; // If UID is shorter than 4 digits, just return it as is
    }
  }

  // Format the timestamp (last_purchase_date)
  String? _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return null;
    }
    DateTime date = timestamp.toDate();
    return "${date.day} ${_getMonthName(date.month)} ${date.year} at ${date.hour}:${date.minute}:${date.second} UTC+5:30";
  }

  // Get the full name of the month
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
}
