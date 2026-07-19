import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OwnerOutletPage extends StatefulWidget {
  final String shopId;

  const OwnerOutletPage({Key? key, required this.shopId}) : super(key: key);

  @override
  State<OwnerOutletPage> createState() => _OwnerOutletPageState();
}

class _OwnerOutletPageState extends State<OwnerOutletPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>>? _stockDetailsFuture;
  Future<List<Map<String, dynamic>>>? _productsFuture;

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _stockDetailsFuture = fetchStockDetails(widget.shopId);
    _productsFuture = fetchProducts();
  }

  // Fetch Stock Details from Stock_Details collection using shopId
Future<Map<String, dynamic>> fetchStockDetails(String shopId) async {
  try {
    print("Fetching stock details for shopId: $shopId");

    // Fetch the document from the 'Shop Owner' collection where shop_id field matches the provided shopId
    QuerySnapshot shopQuerySnapshot = await _firestore
        .collection('Shop Owner')
        .where('shop_id', isEqualTo: shopId)  // Match the field shop_id in Shop Owner collection
        .limit(1)  // Limit to 1 document
        .get();

    // Check if we have a matching document in the 'Shop Owner' collection
    if (shopQuerySnapshot.docs.isEmpty) {
      print("No matching shop found for shopId: $shopId");
      return {};  // Return empty map if no matching shop is found
    }

    // Get the document ID from the matched document
    String shopOwnerDocId = shopQuerySnapshot.docs.first.id;
    print("Found shop document with ID: $shopOwnerDocId");

    // Now fetch the stock details using the shopOwnerDocId
    DocumentSnapshot docSnapshot = await _firestore
        .collection('Stock_Details')
        .doc(shopOwnerDocId)  // Use the document ID from Shop Owner collection
        .get();

    if (!docSnapshot.exists) {
      print("No stock details found for shopId: $shopId");
      return {};  // Return empty map if no stock details found
    }

    print("Stock details found: ${docSnapshot.data()}");
    return docSnapshot.data() as Map<String, dynamic>;  // Return stock details as a map
  } catch (e) {
    print('Error fetching stock details: $e');
    return {};  // Return empty map in case of error
  }
}


  // Fetch product details from Product_Category collection
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Product_Category').get();
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'image': doc['image'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Update stock quantity
  Future<void> updateStock(int index) async {
    if (widget.shopId == null) return;

    try {
      String productKey = 'product_${index + 1}';
      int? stockToSubtract = int.tryParse(_controllers[productKey]?.text ?? '');
      if (stockToSubtract == null || stockToSubtract <= 0) return;

      DocumentReference stockDoc = _firestore.collection('Stock_Details').doc(widget.shopId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnapshot = await transaction.get(stockDoc);
        if (freshSnapshot.exists) {
          Map<String, dynamic> stockData = freshSnapshot.data() as Map<String, dynamic>;

          // Check if 'products' field exists
          if (stockData['products'] != null) {
            int currentStock = stockData['products'][productKey]?['currentStock'] ?? 0;

            if (currentStock >= stockToSubtract) {
              transaction.update(stockDoc, {
                'products.$productKey.currentStock': currentStock - stockToSubtract,
              });
            } else {
              // Show error message if not enough stock
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not enough stock available.')),
              );
              throw Exception('Not enough stock available.');
            }
          } else {
            print("No products data found.");
          }
        }
      });

      setState(() {
        _stockDetailsFuture = fetchStockDetails(widget.shopId); // Refresh stock details
      });

      _controllers[productKey]?.clear(); // Clear the input field
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock Updated Successfully')),
      );
    } catch (e) {
      print("Error updating stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outlet Stock Management',style: TextStyle(color: Colors.white),),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: widget.shopId == null
          ? const Center(child: Text('No shop ID found'))
          : Container(
              // Gradient Background
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 255, 255, 255),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _stockDetailsFuture,
                builder: (context, stockSnapshot) {
                  if (stockSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (stockSnapshot.hasError) {
                    print('Error fetching stock data: ${stockSnapshot.error}');
                    return const Center(child: Text('Error fetching stock data.'));
                  } else if (!stockSnapshot.hasData || stockSnapshot.data!.isEmpty) {
                    print('No stock data found for shopId.');
                    return const Center(child: Text('No stock data available.'));
                  }

                  Map<String, dynamic> stockData = stockSnapshot.data!;

                  print('Stock data: $stockData'); // Add logging to check the data structure

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _productsFuture,
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (productSnapshot.hasError || !productSnapshot.hasData || productSnapshot.data!.isEmpty) {
                        return const Center(child: Text('No products available.'));
                      }

                      List<Map<String, dynamic>> products = productSnapshot.data!;

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> product = products[index];
                          String productKey = 'product_${index + 1}'; // Correct key generation
                          String productName = product['name'];
                          String productImage = product['image'];

                          // Fetch current stock from stockData
                          int currentStock = stockData['products'][productKey]?['currentStock'] ?? 0;

                          // Initialize controllers for stock updates
                          if (_controllers[productKey] == null) {
                            _controllers[productKey] = TextEditingController();
                          }

                          return Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(productImage),
                                    radius: 30,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          productName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          'Current Stock: $currentStock',
                                          style: TextStyle(color: const Color.fromARGB(255, 89, 87, 87)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: TextField(
                                          controller: _controllers[productKey],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: 'Subtract',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      ElevatedButton(
                                        onPressed: () {
                                          updateStock(index); // Pass the index to updateStock
                                        },
                                        child: const Text('Save'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
