import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StockPage extends StatefulWidget {
  @override
  _StockPageState createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<Map<String, dynamic>>> _shops;
  late Future<List<Map<String, dynamic>>> _products;

  // Map to store TextEditingControllers for each product's stock allocation
  Map<String, Map<String, TextEditingController>> controllers = {};

  @override
  void initState() {
    super.initState();
    _shops = fetchShops();
    _products = fetchProducts();
  }

  // Fetch all shops from the 'Shop Owner' collection
  Future<List<Map<String, dynamic>>> fetchShops() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Shop Owner').get();
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'store_name': doc['store_name'],
              'shop_id': doc['shop_id'],
              'name': doc['name'],
            })
        .toList();
  }

  // Fetch all products from the 'Product_Category' collection
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Product_Category').get();
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'],
              'image': doc['image'],
              'documentLink': doc.reference, // Store the actual DocumentReference here
            })
        .toList();
  }

  // Fetch stock details from the 'Stock_Details' collection for a specific shop
  Future<Map<String, dynamic>> fetchStockDetails(String shopId) async {
    DocumentSnapshot docSnapshot = await _firestore.collection('Stock_Details').doc(shopId).get();
    if (!docSnapshot.exists) {
      await initializeStock(shopId, await fetchProducts());
      await Future.delayed(const Duration(milliseconds: 500));
      docSnapshot = await _firestore.collection('Stock_Details').doc(shopId).get();
    }
    return docSnapshot.exists ? docSnapshot.data() as Map<String, dynamic> : {};
  }

  // Initialize stock details when a new shop is added (if not already initialized)
  Future<void> initializeStock(String shopId, List<Map<String, dynamic>> products) async {
    DocumentReference stockDoc = _firestore.collection('Stock_Details').doc(shopId);
    DocumentSnapshot stockSnapshot = await stockDoc.get();
    if (!stockSnapshot.exists) {
      Map<String, dynamic> stockData = {};
      for (int i = 0; i < products.length; i++) {
        String productKey = 'product_${i + 1}';
        stockData[productKey] = {
          'stockAllotted': 0,
          'currentStock': 0,
          'documentLink': products[i]['documentLink'], // Store the Firestore DocumentReference here
        };
      }
      await stockDoc.set({
        'shopId': shopId,
        'products': stockData,
      });
    }
  }

  // Update stock details (to be triggered by button)
  Future<void> updateStock(String shopId, String productKey) async {
    try {
      int? stockAllocated = int.tryParse(controllers[shopId]?[productKey]?.text ?? '');
      if (stockAllocated == null) return;

      DocumentReference stockDoc = _firestore.collection('Stock_Details').doc(shopId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshSnapshot = await transaction.get(stockDoc);
        if (freshSnapshot.exists) {
          Map<String, dynamic> stockData = freshSnapshot.data() as Map<String, dynamic>;
          int currentStock = stockData['products'][productKey]['currentStock'] ?? 0;
          if (currentStock + stockAllocated >= 0) {
            transaction.update(stockDoc, {
              'products.$productKey.stockAllotted': FieldValue.increment(stockAllocated),
              'products.$productKey.currentStock': currentStock + stockAllocated,
            });
          } else {
            throw Exception('Stock cannot be negative');
          }
        }
      });

      // Refresh the UI after successful update
      setState(() {}); // Triggers a rebuild to fetch the latest data
    } catch (error) {
      print("Error updating stock: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating stock: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Stock Management',style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),),
      backgroundColor: Color.fromARGB(255, 0, 0, 0),
      iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255), // Color 1
              Color.fromARGB(255, 217, 216, 213), // Color 2
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _shops,
          builder: (context, shopSnapshot) {
            if (shopSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (shopSnapshot.hasError) {
              return Center(child: Text('Error loading shops'));
            } else if (!shopSnapshot.hasData || shopSnapshot.data!.isEmpty) {
              return Center(child: Text('No shops available'));
            }

            List<Map<String, dynamic>> shops = shopSnapshot.data!;

            return ListView.builder(
              itemCount: shops.length,
              itemBuilder: (context, shopIndex) {
                Map<String, dynamic> shop = shops[shopIndex];
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchStockDetails(shop['id']),
                  builder: (context, stockSnapshot) {
                    if (stockSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text(shop['store_name']),
                        subtitle: Text('Loading stock details...'),
                      );
                    } else if (stockSnapshot.hasError) {
                      return ListTile(
                        title: Text(shop['store_name']),
                        subtitle: Text('Error loading stock details'),
                      );
                    }

                    Map<String, dynamic> stockData = stockSnapshot.data!;

                    // Initialize controllers for each product when they are loaded
                    if (controllers[shop['id']] == null) {
                      controllers[shop['id']] = {};
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: Color.fromARGB(255, 195, 195, 195),  // Set a single background color here
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(shop['store_name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _products,
                                builder: (context, productSnapshot) {
                                  if (productSnapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (productSnapshot.hasError) {
                                    return Center(child: Text('Error loading products'));
                                  } else if (!productSnapshot.hasData || productSnapshot.data!.isEmpty) {
                                    return Center(child: Text('No products available'));
                                  }

                                  List<Map<String, dynamic>> products = productSnapshot.data!;

                                  return Column(
                                    children: products.map((product) {
                                      String productId = product['id'];
                                      String productName = product['name'];
                                      String productImage = product['image'];
                                      var productDocumentLink = product['documentLink']; // Firestore DocumentReference

                                      String productKey = 'product_${products.indexOf(product) + 1}';
                                      int currentStock = stockData['products']?[productKey]?['currentStock'] ?? 0;

                                      // Initialize the TextEditingController only once
                                      if (controllers[shop['id']]?[productKey] == null) {
                                        controllers[shop['id']]?[productKey] = TextEditingController();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundImage: NetworkImage(productImage),
                                              radius: 25,
                                            ),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                Container(
                                                  width: 100,
                                                  child: TextField(
                                                    controller: controllers[shop['id']]?[productKey],
                                                    keyboardType: TextInputType.number,
                                                    decoration: InputDecoration(labelText: 'Allotted Stock'),
                                                  ),
                                                ),
                                                Text(
                                                  'Current Stock: $currentStock',
                                                  style: TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    updateStock(shop['id'], productKey);
                                                  },
                                                  child: Text('Save',style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
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
