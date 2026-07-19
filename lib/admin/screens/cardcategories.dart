import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _categoryNameController = TextEditingController();

  // Function to fetch the category documents from Firestore
  Stream<List<Map<String, dynamic>>> fetchCategories() {
    return _firestore.collection('Category').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        List<dynamic> productList = doc['product'] ?? [];
        return {
          'category_name': doc['category_name'],
          'products': productList,
        };
      }).toList();
    });
  }

  // Function to remove a product from the category's product array
  Future<void> removeProduct(String categoryName, String productId) async {
    try {
      print("Attempting to remove product with ID: $productId from category: $categoryName");

      // Query the Category collection to find the document with the given category name
      QuerySnapshot categorySnapshot = await _firestore
          .collection('Category')
          .where('category_name', isEqualTo: categoryName)
          .get();
    
      if (categorySnapshot.docs.isEmpty) {
        print("No category document found with name '$categoryName'");
        return; // Category not found, so return
      }

      // Get the first matching document (assuming category names are unique)
      DocumentSnapshot categoryDoc = categorySnapshot.docs.first;
      print("Found category document with ID: ${categoryDoc.id}");

      // Check if the 'product' field exists and is an array
      List<dynamic> products = categoryDoc['product'];
      if (products == null || products.isEmpty) {
        print("No products found in category '$categoryName'");
        return; // No products to remove
      }

      // Find the product to remove
      Map<String, dynamic>? productToRemove;
      for (var product in products) {
        if (product['product_id'] == productId) {
          productToRemove = product;
          break;
        }
      }

      if (productToRemove == null) {
        print("No product found with product_id '$productId' in category '$categoryName'");
        return; // Product not found in the category
      }

      // Remove the full product object (not just the product_id)
      await categoryDoc.reference.update({
        'product': FieldValue.arrayRemove([productToRemove])
      });

      print("Product removed successfully from category '$categoryName'");
    } catch (e) {
      print('Error removing product: $e');
    }
  }

  // Function to add a new category
  Future<void> addCategory(String categoryName) async {
    try {
      await _firestore.collection('Category').add({
        'category_name': categoryName,
        'product': [],
      });
    } catch (e) {
      print('Error adding category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Categories',style: TextStyle(color: Colors.white),),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
                  const Color.fromARGB(255, 255, 255, 255),
                  const Color.fromARGB(255, 255, 255, 255),], // Add your preferred colors here
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  String categoryName = _categoryNameController.text;
                  if (categoryName.isNotEmpty) {
                    addCategory(categoryName);
                    _categoryNameController.clear();
                  }
                },
                child: Text('Add Category',style: TextStyle(color: Colors.black),),
              ),
              SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>( 
                  stream: fetchCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    List<Map<String, dynamic>> categories = snapshot.data!;

                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, categoryIndex) {
                        String categoryName = categories[categoryIndex]['category_name'];
                        List<dynamic> products = categories[categoryIndex]['products'];

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: products.length,
                                  itemBuilder: (context, productIndex) {
                                    Map<String, dynamic> product = products[productIndex];
                                    String productId = product['product_id'];
                                    String price = product['price'];
                                    String quantity = product['quantity'];

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: _firestore
                                          .collection('Product_Category')
                                          .doc(productId)
                                          .get(),
                                      builder: (context, productSnapshot) {
                                        if (!productSnapshot.hasData) {
                                          return SizedBox();
                                        }

                                        var productDetails = productSnapshot.data!;
                                        String productName = productDetails['name'];
                                        String imageUrl = productDetails['image'];

                                        return Card(
                                          elevation: 3,
                                          margin: EdgeInsets.symmetric(vertical: 5),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Row(
                                              children: [
                                                Image.network(
                                                  imageUrl,
                                                  width: 50,
                                                  height: 50,
                                                  fit: BoxFit.cover,
                                                ),
                                                SizedBox(width: 10),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      productName,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text('Price: \₹ ${price}'),
                                                    Text('Quantity: ${quantity}'),
                                                  ],
                                                ),
                                                Spacer(),
                                                IconButton(
                                                  icon: Icon(Icons.delete),
                                                  onPressed: () {
                                                    removeProduct(
                                                      categories[categoryIndex]['category_name'],
                                                      productId,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
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
        ),
      ),
    );
  }
}
