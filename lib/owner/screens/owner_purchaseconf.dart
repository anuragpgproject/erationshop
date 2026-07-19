import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OwnerOrdersPage extends StatefulWidget {
  @override
  _OwnerOrdersPageState createState() => _OwnerOrdersPageState();
}

class _OwnerOrdersPageState extends State<OwnerOrdersPage> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  bool _isLoading = true;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isVerifying = false;
  String? mobileNo;
  String? verificationSid;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await firestore.collection('Orders_all').get();

      setState(() {
        _orders = querySnapshot.docs.map((doc) {
          return {
            'order_id': doc.id,
            'status': doc['status'],
            'total_amount': doc['total_amount'],
            'timestamp': doc['timestamp'],
            'items': doc['items'],
            'user_id': doc['user_id'],
            'purchased': doc['purchased'] ?? 'not purchased',
          };
        }).toList();

        _filteredOrders = List.from(_orders);
      });
    } catch (e) {
      print("Error fetching orders: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterOrders() {
    setState(() {
      _filteredOrders = _orders
          .where((order) => order['order_id']
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _sendOTPAndUpdatePurchase(String orderId) async {
    // Get the user_id from the order
    final order = _orders.firstWhere((order) => order['order_id'] == orderId);
    final userId = order['user_id'];

    // Fetch the card document to get the mobile number
    var cardDoc = await firestore
        .collection('Card')
        .where('card_no', isEqualTo: userId) // Assuming user_id is same as card_no
        .limit(1)
        .get();

    if (cardDoc.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Card number not found for the user')),
        );
      }
      return;
    }

    // Get the mobile number associated with the card
    mobileNo = cardDoc.docs[0]['mobile_no'];

    // Send OTP to the mobile number using Twilio
    bool otpSent = await _sendOTPViaTwilio(mobileNo!);
    if (otpSent) {
      // Once OTP is sent successfully, show OTP input dialog
      if (mounted) {
        _showOTPInputDialog(orderId);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP')),
        );
      }
    }
  }

  Future<bool> _sendOTPViaTwilio(String mobileNo) async {
    final String? accountSid = dotenv.env['accountSid'];  // Your Twilio Account SID
    final String? authToken = dotenv.env['authToken'];  // Your Twilio Auth Token
    final String? serviceSid = dotenv.env['serviceSid'];  // Your Twilio Verify Service SID

    final String url = 'https://verify.twilio.com/v2/Services/$serviceSid/Verifications';
    final Map<String, String> data = {
      'To': mobileNo,
      'Channel': 'sms',
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),

      },
      body: data,
    );

    if (response.statusCode == 201) {
      print('OTP sent successfully');
      final responseData = json.decode(response.body);
      verificationSid = responseData['sid'];
      return true;  // OTP sent successfully
    } else {
      print('Failed to send OTP: ${response.body}');
      return false;  // OTP sending failed
    }
  }

  Future<void> _showOTPInputDialog(String orderId) async {
    TextEditingController otpController = TextEditingController();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Enter OTP'),
            content: TextField(
              controller: otpController,
              decoration: InputDecoration(hintText: 'Enter OTP'),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  bool otpVerified = await _verifyOTP(otpController.text);
                  if (otpVerified) {
                    await _updatePurchaseStatus(orderId);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('OTP verification failed')),
                      );
                    }
                  }
                },
                child: Text('Verify'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool> _verifyOTP(String userOtp) async {
    final String? accountSid = dotenv.env['accountSid'];  // Your Twilio Account SID
    final String? authToken = dotenv.env['authToken'];  // Your Twilio Auth Token
    final String? serviceSid = dotenv.env['serviceSid'];  // Your Twilio Verify Service SID
    final String url = 'https://verify.twilio.com/v2/Services/$serviceSid/VerificationCheck';
    final Map<String, String> data = {
      'To': mobileNo!,  // The mobile number to which the OTP was sent
      'Code': userOtp,  // The OTP entered by the user
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$accountSid:$authToken')),
      },
      body: data,
    );

    if (response.statusCode == 200) {
      print('OTP verified successfully');
      return true;
    } else {
      print('OTP verification failed: ${response.body}');
      return false;
    }
  }

  Future<void> _updatePurchaseStatus(String orderId) async {
    // Get shopId from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? shopId = prefs.getString('shop_id');

    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shop ID not found')),
      );
      return;
    }

    try {
      // Update the order status to "purchased" and add shopId
      await firestore.collection('Orders_all').doc(orderId).update({
        'purchased': 'purchased',
        'shop_id': shopId,  // Save the shopId in the order document
      });

      // Fetch the updated orders
      _fetchOrders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase status updated to "purchased" and shopId saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating purchase status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Confirmation', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filterOrders(),
            ),
            SizedBox(height: 16),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 5,
                          child: ListTile(
                            title: Text('Order ID: ${order['order_id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${order['status']}'),
                                Text('Total Amount: ₹${order['total_amount']}'),
                                Text('Date: ${order['timestamp'].toDate()}'),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: (order['items'] as List).map<Widget>((item) {
                                    return Text(
                                        'Item: ${item['name']}  Quantity: ${item['quantity']}');
                                  }).toList(),
                                ),
                                Text(
                                  'Purchase Status: ${order['purchased']}',
                                  style: TextStyle(
                                    color: order['purchased'] == 'Not Purchased'
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            trailing: order['purchased'] == 'Not Purchased'
                                ? IconButton(
                                    icon: Icon(Icons.check_circle),
                                    onPressed: () => _sendOTPAndUpdatePurchase(order['order_id']),
                                  )
                                : null,
                          ),
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
