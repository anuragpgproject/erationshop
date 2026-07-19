import 'dart:io'; // For File type
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // Add http dependency for Cloudinary API
import 'dart:convert';

class AdminProduct extends StatefulWidget {
  const AdminProduct({super.key});

  @override
  _AdminProductState createState() => _AdminProductState();
}

class _AdminProductState extends State<AdminProduct> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  late Stream<QuerySnapshot> _categoryStream;
  late Stream<QuerySnapshot> _productCategoryStream;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'bpl'; // Default category
  File? _imageFile; // To store the selected image

  // Cloudinary credentials
  final String cloudName = "dfoid6qev";
  final String apiKey = "948219642975793";
  final String apiSecret = "Zzea0hJAlegwGmiGVRBKK8inbOs";
  final String presetName = "products"; // The preset name you set up on Cloudinary

  @override
  void initState() {
    super.initState();
    _categoryStream = _firestore.collection('Category').snapshots();
    _productCategoryStream = _firestore.collection('Product_Category').snapshots();
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Save the image file
      });
    }
  }

  // Upload image to Cloudinary
  Future<String> _uploadImageToCloudinary() async {
    if (_imageFile == null) return ''; // If no image is selected, return an empty string

    try {
      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = presetName
        ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));  // Attach the image file

      final response = await request.send();  // Send the request

      if (response.statusCode == 200) {
        final responseBody = await http.Response.fromStream(response);
        final data = json.decode(responseBody.body);

        return data['secure_url'];  // Return the secure image URL
      } else {
        throw Exception("Error uploading image: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error uploading image: $e");
    }
  }

  // Add a new product to Firestore
  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String name = _nameController.text;
      double price = double.tryParse(_priceController.text) ?? 0.0;
      int quantity = int.tryParse(_quantityController.text) ?? 0;

      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImageToCloudinary(); // Upload the image to Cloudinary and get the URL
      }

      // Add product to Product_Category collection
      var productRef = await _firestore.collection('Product_Category').add({
        'name': name,
        'description': 'na',
        'image': imageUrl.isNotEmpty ? imageUrl : "na", // Save the image URL in Firestore
      });

      // Add the product to the selected category
      await _addProductToCategory(productRef.id, price, quantity);

      // Clear the form fields
      _nameController.clear();
      _priceController.clear();
      _quantityController.clear();
      setState(() {
        _imageFile = null; // Clear the selected image
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Add product to the selected category
  Future<void> _addProductToCategory(String productId, double price, int quantity) async {
    try {
      var categoryQuerySnapshot = await _firestore
          .collection('Category')
          .where('category_name', isEqualTo: _selectedCategory)
          .get();

      if (categoryQuerySnapshot.docs.isNotEmpty) {
        var categoryDoc = categoryQuerySnapshot.docs.first;
        
        await _firestore.collection('Category').doc(categoryDoc.id).update({
          'product': FieldValue.arrayUnion([{
            'product_id': productId,
            'price': price.toString(),
            'quantity': quantity.toString(),
          }]),
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added to the selected category')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category not found')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Remove product from Firestore
Future<void> _removeProduct(String productId, String imageUrl) async {
  try {
    // Delete the product from the Product_Category collection
    await _firestore.collection('Product_Category').doc(productId).delete();

    // Remove the product from the selected category's product array
    await _removeProductFromCategory(productId);

    // Optionally delete the image from Cloudinary (if necessary)
    if (imageUrl.isNotEmpty && imageUrl != "na") {
      final cloudinaryDeleteUrl = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/destroy");
      final request = http.MultipartRequest('POST', cloudinaryDeleteUrl)
        ..fields['public_id'] = Uri.parse(imageUrl).pathSegments.last;

      final response = await request.send();

      if (response.statusCode != 200) {
        throw Exception("Error deleting image from Cloudinary: ${response.statusCode}");
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product removed successfully')));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}


  // Remove product from the selected category
 Future<void> _removeProductFromCategory(String productId) async {
  try {
    // Fetch all Category documents
    var categoryQuerySnapshot = await _firestore.collection('Category').get();

    // Iterate through each category document
    for (var categoryDoc in categoryQuerySnapshot.docs) {
      // Check if the product_id exists in the 'product' array
      var products = categoryDoc['product'] as List<dynamic>;
      
      // Find the product that needs to be removed based on product_id
      var productToRemove = products.firstWhere(
        (product) => product['product_id'] == productId,
        orElse: () => null, // If no product matches, return null
      );

      if (productToRemove != null) {
        // If the product is found, remove it from the 'product' array
        await _firestore.collection('Category').doc(categoryDoc.id).update({
          'product': FieldValue.arrayRemove([productToRemove]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product removed from the selected category')),
        );
      }
    }
  } catch (e) {
    throw Exception("Error removing product from category: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Manage Products',style: TextStyle(color: Colors.white),),
            backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: const IconThemeData(color: Colors.white),

      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Manage Existing Products',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 19, 19, 20)),
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: _productCategoryStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final products = snapshot.data!.docs;
                  return Column(
                    children: products.map((productDoc) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 5.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        child: ListTile(
                          leading: productDoc['image'] != "na"
                              ? Image.network(productDoc['image'], width: 60, height: 60, fit: BoxFit.cover)
                              : const SizedBox(height: 60, width: 60,),
                          title: Text(productDoc['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Confirm deletion before removing product
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Confirm Deletion"),
                                  content: const Text("Are you sure you want to delete this product?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _removeProduct(productDoc.id, productDoc['image']);
                                      },
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
              const Text(
                'Add a New Product',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        color: Colors.grey[200],
                        width: 200,
                        height: 200,
                        child: _imageFile == null
                            ? const Center(child: Text("Tap to pick an image"))
                            : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a product name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a price' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter a quantity' : null,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _categoryStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        final categories = snapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Select Category'),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: categories.map((categoryDoc) {
                                return DropdownMenuItem<String>(
                                  value: categoryDoc['category_name'],
                                  child: Text(categoryDoc['category_name']),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                });
                              },
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addProduct,
                      child: const Text('Add Product'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

