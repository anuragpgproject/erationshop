import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAllowPurchase extends StatefulWidget {
  @override
  _AdminAllowPurchaseState createState() => _AdminAllowPurchaseState();
}

class _AdminAllowPurchaseState extends State<AdminAllowPurchase> {
  bool _isLoading = false;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isAllowingPurchases = false;  // Tracks whether purchases are allowed
  String _allowanceTimestamp = '';  // To store the timestamp when purchases are allowed
  String _allowanceMonth = '';  // To store the month when purchases are allowed
  List<Map<String, String>> _previousAllowances = [];  // To store previous allowance records

  // Function to toggle allow purchases
  Future<void> _toggleAllowPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isAllowingPurchases) {
        // Store the timestamp and month in a new collection 'PurchaseAllowances'
        DateTime currentTime = DateTime.now();
        String formattedTimestamp = currentTime.toString();
        String formattedMonth = "${currentTime.month}-${currentTime.year}";

        await firestore.collection('PurchaseAllowances').add({
          'timestamp': formattedTimestamp,
          'month': formattedMonth,
        });

        // Update the timestamp and month to display below the button
        setState(() {
          _allowanceTimestamp = formattedTimestamp;
          _allowanceMonth = formattedMonth;
        });

        // Fetch all previous allowances to display
        _fetchPreviousAllowances();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAllowingPurchases ? 'Purchasing allowed' : 'Purchasing disallowed')),
      );
    } catch (e) {
      print('Error toggling purchases: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update purchases')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch previous allowances
  Future<void> _fetchPreviousAllowances() async {
    try {
      QuerySnapshot snapshot = await firestore.collection('PurchaseAllowances').get();
      List<Map<String, String>> allowances = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?; // Ensures the data is treated as a Map
        if (data != null) {
          allowances.add({
            'timestamp': data['timestamp'] ?? 'No timestamp', // Provide a default value if null
            'month': data['month'] ?? 'No month', // Provide a default value if null
          });
        }
      }

      setState(() {
        _previousAllowances = allowances;
      });
    } catch (e) {
      print('Error fetching previous allowances: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch previous allowances when the page loads
    _fetchPreviousAllowances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Activation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activate Purchases',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(10),  // Padding inside the box
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),  // Border color
                borderRadius: BorderRadius.circular(8),  // Rounded corners
              ),
              child: Text(
                'Press the "Allow Purchase" button to activate customer purchases.',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            SizedBox(height: 20),
            // The Switch for toggling "Allow Purchases"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Allow Purchases:',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
                Switch(
                  value: _isAllowingPurchases,
                  onChanged: (value) {
                    setState(() {
                      _isAllowingPurchases = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            // Display the "Allow Purchases" button only when the toggle is on
            if (_isAllowingPurchases) 
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleAllowPurchases, // Disable the button while loading
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, // Button color
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Allow Purchases',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            SizedBox(height: 20),
            // Display the timestamp and month when purchases were allowed
            if (_allowanceTimestamp.isNotEmpty) 
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Purchases Allowed On: $_allowanceTimestamp',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    'Month: $_allowanceMonth',
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ],
              ),
            SizedBox(height: 20),
            // Display the previous allowances
            if (_previousAllowances.isNotEmpty)
              Text(
                'Previous Allowances:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _previousAllowances.length,
              itemBuilder: (context, index) {
                var allowance = _previousAllowances[index];
                return Card(
                  elevation: 2,
                  child: ListTile(
                    title: Text('Allowed On: ${allowance['timestamp']}'),
                    subtitle: Text('Month: ${allowance['month']}'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
