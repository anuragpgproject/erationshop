import 'dart:io';
import 'dart:convert'; // Added for JSON decoding
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http; // Import http package

class AdminShopPage extends StatefulWidget {
  const AdminShopPage({super.key});

  @override
  State<AdminShopPage> createState() => _AdminShopPageState();
}

class _AdminShopPageState extends State<AdminShopPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _shopIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isEditing = false;
  String? _shopIdToEdit;
  bool _isPasswordVisible = false;
  late double _latitude;
  late double _longitude;



  // Function to add a new shop
  Future<void> _addShop() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final newShop = {
          'name': _nameController.text,
          'store_name': _storeNameController.text,
          'address': _addressController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'shop_id': _shopIdController.text,
          'password': _passwordController.text,
          'lat': _latitude,
          'long': _longitude,
        };

        await FirebaseFirestore.instance.collection('Shop Owner').add(newShop);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ration-Shop added successfully')),
        );

        _clearForm();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add Ration-shop')),
        );
      }
    }
  }

  // Function to clear the form fields
  void _clearForm() {
    _nameController.clear();
    _storeNameController.clear();
    _addressController.clear();
    _emailController.clear();
    _phoneController.clear();
    _shopIdController.clear();
    _passwordController.clear();
    setState(() {
      _isEditing = false;
      _shopIdToEdit = null;
      _isPasswordVisible = false;
      _latitude = 0.0;
      _longitude = 0.0;
    });
  }

  // Function to handle geocoding (search address and get latitude and longitude)
  Future<void> getLatLongFromAddress(String address) async {
    try {
      // Make a request to the Nominatim API to get geocoding data
      String url = 'https://nominatim.openstreetmap.org/search?format=json&q=$address';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data.isNotEmpty) {
          double lat = double.parse(data[0]['lat']);
          double lng = double.parse(data[0]['lon']);

          // Set latitude and longitude to the variables
          setState(() {
            _latitude = lat;
            _longitude = lng;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address converted to coordinates')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No location found for the address')),
          );
        }
      } else {
        print('Error with geocoding API');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error in geocoding address')),
        );
      }
    } catch (e) {
      print('Error in geocoding address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error in geocoding address')),
      );
    }
  }

  Future<void> _updateShop() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final updatedShop = {
          'name': _nameController.text,
          'store_name': _storeNameController.text,
          'address': _addressController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'shop_id': _shopIdController.text,
          'password': _passwordController.text,
          'lat': _latitude,
          'long': _longitude,
        };

        // Update the shop in Firestore
        await FirebaseFirestore.instance
            .collection('Shop Owner')
            .doc(_shopIdToEdit) // Use the shop ID to find the document
            .update(updatedShop);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop updated successfully')),
        );

        _clearForm(); // Clear form after successful update
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update shop')),
        );
      }
    }
  }

  // Function to load the list of shops from Firestore
  Stream<List<Map<String, dynamic>>> _getShopList() {
    return FirebaseFirestore.instance
        .collection('Shop Owner')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Function to load shop data for editing
  Future<void> _loadShopData(String shopId) async {
    try {
      // Get shop data from Firestore where shop_id matches the given value
      var querySnapshot = await FirebaseFirestore.instance
          .collection('Shop Owner')
          .where('shop_id', isEqualTo: shopId) // Query by shop_id
          .limit(1) // Ensure only one document is retrieved
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var shopDoc = querySnapshot.docs.first; // Retrieve the first (and only) document

        var shopData = shopDoc.data()!;

        // Pre-fill form fields with retrieved data
        _nameController.text = shopData['name'] ?? '';
        _storeNameController.text = shopData['store_name'] ?? '';
        _addressController.text = shopData['address'] ?? '';
        _emailController.text = shopData['email'] ?? '';
        _phoneController.text = shopData['phone'] ?? '';
        _shopIdController.text = shopData['shop_id'] ?? '';
        _passwordController.text = shopData['password'] ?? '';
        _latitude = shopData['lat'] ?? 0.0;
        _longitude = shopData['long'] ?? 0.0;

        setState(() {
          _isEditing = true;
          _shopIdToEdit = shopId; // Set the ID for editing
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading shop data')),
      );
    }
  }

  // Function to remove shop
  Future<void> _removeShop(String shopId) async {
    try {
      await FirebaseFirestore.instance.collection('Shop Owner').doc(shopId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shop removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove shop')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Shop' : 'Add Shop', style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255))),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 255, 255, 255),
              const Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Shop Owner Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the shop owner name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _storeNameController,
                        decoration: const InputDecoration(labelText: 'Store Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the store name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the address';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () => getLatLongFromAddress(_addressController.text), // Pass address to get coordinates
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 208, 207, 206),
                        ),
                        child: const Text('Get Latitude & Longitude', style: TextStyle(color: Colors.black)),
                      ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the email';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(labelText: 'Phone Number'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _shopIdController,
                        decoration: const InputDecoration(labelText: 'Shop ID'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the shop ID';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the password';
                          }
                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ElevatedButton(
                          onPressed: _isEditing ? _updateShop : _addShop,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 196, 185, 185),
                          ),
                          child: Text(_isEditing ? 'Update Shop' : 'Add Shop'),
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<List<Map<String, dynamic>>>( 
                  stream: _getShopList(), 
                  builder: (context, snapshot) { 
                    if (snapshot.connectionState == ConnectionState.waiting) { 
                      return Center(child: CircularProgressIndicator()); 
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) { 
                      return Center(child: Text("No shops found"));
                    }

                    final shopList = snapshot.data!; 
                    return ListView.builder( 
                      shrinkWrap: true, 
                      itemCount: shopList.length, 
                      itemBuilder: (context, index) { 
                        final shop = shopList[index]; 
                        return ListTile( 
                          title: Text(shop['store_name']), 
                          subtitle: Text(shop['address']), 
                          trailing: Row( 
                            mainAxisSize: MainAxisSize.min, 
                            children: [ 
                              IconButton( 
                                icon: Icon(Icons.edit), 
                                onPressed: () => _loadShopData(shop['shop_id']), 
                              ), 
                              IconButton( 
                                icon: Icon(Icons.delete), 
                                onPressed: () => _removeShop(shop['shop_id']), 
                              ), 
                            ], 
                          ), 
                        ); 
                      }, 
                    ); 
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
