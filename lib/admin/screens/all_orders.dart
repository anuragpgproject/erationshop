import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Orders',style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Card No.',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Orders_all')
                  .where('user_id', isGreaterThanOrEqualTo: _searchQuery)
                  .where('user_id', isLessThan: _searchQuery + 'z')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No orders found.'));
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final List<dynamic> items = order['items'];

                    return Card(
                      margin: EdgeInsets.all(10),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Time
                            Text(
                              'Ordered on: ${order['timestamp'].toDate().toString()}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Divider(),
                            // Display Card Number
                            Text(
                              'Card No: ${order['user_id']}',
                              style: TextStyle(fontSize: 16),
                            ),
                            Divider(),
                            // Purchased status
                            Text(
                              'Purchase Status: ${order['purchased']}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: order['purchased'] == 'purchased'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Divider(),
                            // Item List
                            ...items.map<Widget>((item) {
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Image.network(
                                  item['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(item['name']),
                                subtitle: Text('Price: \$${item['price']}'),
                                trailing: Text('Qty: ${item['quantity']}'),
                              );
                            }).toList(),
                            Divider(),
                            // Total Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount: \$${order['total_amount']}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // Display Shop ID if Purchased
                                if (order['purchased'] == 'purchased')
                                  Text(
                                    'Distributor ID: ${order['shop_id']}',
                                    style: TextStyle(fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            // Status
                            Text(
                              'Payment Status: ${order['status']}',
                              style: TextStyle(
                                color: order['status'] == 'Success'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
    );
  }
}
