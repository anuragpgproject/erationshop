import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddCardPage extends StatefulWidget {
  const AddCardPage({super.key});

  @override
  _AddCardPageState createState() => _AddCardPageState();
}

class _AddCardPageState extends State<AddCardPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _cardNoController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _localBodyController = TextEditingController();
  final TextEditingController _wardNoController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _monthlyIncomeController = TextEditingController();

  String? _electrifiedValue;
  String? _lpgValue;

  int membersCount = 0;
  List<TextEditingController> _memberNameControllers = [];
  List<TextEditingController> _memberAgeControllers = [];
  List<TextEditingController> _memberOccupationControllers = [];
  List<TextEditingController> _memberUIDControllers = [];

  List<Map<String, dynamic>> _cardDetailsList = [];
  List<String> _cardIds = [];

  bool _isLoading = true;
  bool _isEditing = false;

  // To store the card being edited
  Map<String, dynamic> _editingCard = {};
  String? _editingCardId;

  // Fetch all card details from Firestore
  Future<void> _fetchAllCards() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Card').get();

      final cards = snapshot.docs.map((doc) {
        return {
          'owner_name': doc['owner_name'] ?? 'Unknown',
          'card_no': doc['card_no'] ?? 'Unknown',
          'category': doc['category'] ?? 'Unknown',
          'mobile_no': doc['mobile_no'] ?? 'Unknown',
          'address': doc['address'] ?? 'Unknown',
          'local_body': doc['local_body'] ?? 'Unknown',
          'ward_no': doc['ward_no'] ?? 'Unknown',
          'house_no': doc['house_no'] ?? 'Unknown',
          'monthly_income': doc['monthly_income'] ?? 'Unknown',
          'electrified': doc['electrified'] ?? 'Unknown',
          'lpg': doc['lpg'] ?? 'Unknown',
          'member_list': doc['member_list'] ?? [],
          'members_count': doc['members_count'] ?? '0',
        };
      }).toList();

      final cardIds = snapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _cardDetailsList = cards;
        _cardIds = cardIds;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching card details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch cards')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Check if card number exists in Firestore
  Future<bool> _checkCardNoExists(String cardNo) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Card')
        .where('card_no', isEqualTo: cardNo)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<void> _addCard() async {
    if (_formKey.currentState?.validate() ?? false) {
      final cardNo = _cardNoController.text;

      // Check if the card number already exists
      bool exists = await _checkCardNoExists(cardNo);
      if (exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card number already exists!')),
        );
        return;
      }

      // Get the category_id based on entered category_name
      String categoryId = await _getCategoryIdByName(_categoryController.text);
      if (categoryId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category not found!')),
        );
        return;
      }

      // Get Product Category to initialize purchase dates
      List<String> productCategoryIds = await _getProductCategoryIds();

     // Step 1: Get the current date-time
DateTime currentDateTime = DateTime.now();

// Step 2: Subtract 31 days from the current date-time
DateTime thirtyOneDaysAgo = currentDateTime.subtract(Duration(days: 31));

// Step 3: Convert the DateTime to a Timestamp
Timestamp timestampThirtyOneDaysAgo = Timestamp.fromDate(thirtyOneDaysAgo);

// Step 4: Use this timestamp when creating the purchase dates
List<Map<String, dynamic>> purchaseDates = productCategoryIds.map((productId) {
  return {
    'product_id': productId,
    'date': timestampThirtyOneDaysAgo, // Set the initial date as 31 days ago
  };
}).toList();


      try {
        await FirebaseFirestore.instance.collection('Card').add({
          'owner_name': _ownerNameController.text,
          'card_no': _cardNoController.text,
          'category': _categoryController.text,
          'category_id': categoryId,  // Add category_id
          'mobile_no': _mobileNoController.text,
          'address': _addressController.text,
          'local_body': _localBodyController.text,
          'ward_no': _wardNoController.text,
          'house_no': _houseNoController.text,
          'monthly_income': _monthlyIncomeController.text,
          'electrified': _electrifiedValue,
          'lpg': _lpgValue,
          'members_count': membersCount.toString(),
          'member_list': List.generate(membersCount, (index) {
            return {
              'name': _memberNameControllers[index].text,
              'age': int.parse(_memberAgeControllers[index].text),
              'occupation': _memberOccupationControllers[index].text,
              'uid_no': _memberUIDControllers[index].text,
            };
          }),
          'purchase_date': purchaseDates,  // Adding the purchase dates array
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully!')),
        );

        // After successful submission, reset the form fields
        setState(() {
          membersCount = 0;
          _memberNameControllers.clear();
          _memberAgeControllers.clear();
          _memberOccupationControllers.clear();
          _memberUIDControllers.clear();
          _ownerNameController.clear();
          _cardNoController.clear();
          _categoryController.clear();
          _mobileNoController.clear();
          _addressController.clear();
          _localBodyController.clear();
          _wardNoController.clear();
          _houseNoController.clear();
          _monthlyIncomeController.clear();
        });

        _fetchAllCards();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add card')),
        );
      }
    }
  }

  // Function to get the Category ID based on the category name
  Future<String> _getCategoryIdByName(String categoryName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Category')
          .where('category_name', isEqualTo: categoryName)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      } else {
        return '';
      }
    } catch (e) {
      print('Error fetching category: $e');
      return '';
    }
  }

  

  // Fetch all product category IDs
  Future<List<String>> _getProductCategoryIds() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Product_Category')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error fetching product categories: $e');
      return [];
    }
  }

  // Update a card's details in Firestore
  Future<void> _updateCard(String cardId) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await FirebaseFirestore.instance.collection('Card').doc(cardId).update({
          'owner_name': _ownerNameController.text,
          'card_no': _cardNoController.text,
          'category': _categoryController.text,
          'mobile_no': _mobileNoController.text,
          'address': _addressController.text,
          'local_body': _localBodyController.text,
          'ward_no': _wardNoController.text,
          'house_no': _houseNoController.text,
          'monthly_income': _monthlyIncomeController.text,
          'electrified': _electrifiedValue,
          'lpg': _lpgValue,
          'members_count': membersCount.toString(),
          'member_list': List.generate(membersCount, (index) {
            return {
              'name': _memberNameControllers[index].text,
              'age': int.parse(_memberAgeControllers[index].text),
              'occupation': _memberOccupationControllers[index].text,
              'uid_no': _memberUIDControllers[index].text,
            };
          }),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card updated successfully!')),
        );

        setState(() {
          _isEditing = false;
          _editingCard = {};
          _editingCardId = null;
          membersCount = 0;
          _memberNameControllers.clear();
          _memberAgeControllers.clear();
          _memberOccupationControllers.clear();
          _memberUIDControllers.clear();
        });

        _fetchAllCards();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update card')),
        );
      }
    }
  }

  // Remove a card from Firestore
  Future<void> _removeCard(String cardId) async {
    try {
      await FirebaseFirestore.instance.collection('Card').doc(cardId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Card removed successfully!')),
      );
      _fetchAllCards();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove card')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAllCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Card', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 255, 255, 255),
              const Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Cards Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _cardDetailsList.isEmpty
                        ? const Center(child: Text('No cards found'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _cardDetailsList.length,
                            itemBuilder: (context, index) {
                              final card = _cardDetailsList[index];
                              final cardId = _cardIds[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Card Number: ${card['card_no']}'),
                                      Text('Owner Name: ${card['owner_name']}'),
                                      Text('Category: ${card['category']}'),
                                      Text('Mobile Number: ${card['mobile_no']}'),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                                _editingCard = card;
                                                _editingCardId = cardId;
                                                _ownerNameController.text = card['owner_name'];
                                                _cardNoController.text = card['card_no'];
                                                _categoryController.text = card['category'];
                                                _mobileNoController.text = card['mobile_no'];
                                                _addressController.text = card['address'];
                                                _localBodyController.text = card['local_body'];
                                                _wardNoController.text = card['ward_no'];
                                                _houseNoController.text = card['house_no'];
                                                _monthlyIncomeController.text = card['monthly_income'];
                                                _electrifiedValue = card['electrified'];
                                                _lpgValue = card['lpg'];

                                                // Load family members
                                                membersCount = int.parse(card['members_count']);
                                                _memberNameControllers = List.generate(membersCount, (index) {
                                                  return TextEditingController(text: card['member_list'][index]['name']);
                                                });
                                                _memberAgeControllers = List.generate(membersCount, (index) {
                                                  return TextEditingController(text: card['member_list'][index]['age'].toString());
                                                });
                                                _memberOccupationControllers = List.generate(membersCount, (index) {
                                                  return TextEditingController(text: card['member_list'][index]['occupation']);
                                                });
                                                _memberUIDControllers = List.generate(membersCount, (index) {
                                                  return TextEditingController(text: card['member_list'][index]['uid_no']);
                                                });
                                              });
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () async {
                                              bool? confirmDelete = await showDialog<bool>(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('Confirm Deletion'),
                                                    content: const Text('Are you sure you want to delete this card?'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop(false);
                                                        },
                                                        child: const Text('Cancel')
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context).pop(true);
                                                        },
                                                        child: const Text('Delete')
                                                      )
                                                    ]
                                                  );
                                                }
                                              );

                                              if (confirmDelete == true) {
                                                await _removeCard(cardId);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                const SizedBox(height: 30),
                const Text(
                  'Enter New Card Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: const Color.fromARGB(255, 201, 199, 199),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(66, 0, 0, 0),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cardholder Name
                        TextFormField(
                          controller: _ownerNameController,
                          decoration: const InputDecoration(labelText: 'Cardholder Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the cardholder name';
                            }
                            if (!RegExp(r"^[a-zA-Z\s.]+$").hasMatch(value)) {
                              return 'Name should not contain digits or special characters except dot(.)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Card No
                        TextFormField(
                          controller: _cardNoController,
                          decoration: const InputDecoration(labelText: 'Card Number'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the card number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Category
                        TextFormField(
                          controller: _categoryController,
                          decoration: const InputDecoration(labelText: 'Category'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the category';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Mobile Number
                        TextFormField(
                          controller: _mobileNoController,
                          decoration: const InputDecoration(labelText: 'Mobile Number'),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the mobile number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Address
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
                        const SizedBox(height: 20),

                        // Local Body
                        TextFormField(
                          controller: _localBodyController,
                          decoration: const InputDecoration(labelText: 'Local Body'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the local body';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Ward No
                        TextFormField(
                          controller: _wardNoController,
                          decoration: const InputDecoration(labelText: 'Ward No'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the ward number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // House No
                        TextFormField(
                          controller: _houseNoController,
                          decoration: const InputDecoration(labelText: 'House No'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the house number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Monthly Income
                        TextFormField(
                          controller: _monthlyIncomeController,
                          decoration: const InputDecoration(labelText: 'Monthly Income'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the monthly income';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Electrified and LPG Radio Buttons
                        Row(
                          children: [
                            Text('Electrified:'),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Yes',
                                  groupValue: _electrifiedValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _electrifiedValue = value;
                                    });
                                  },
                                ),
                                const Text('Yes'),
                                Radio<String>(
                                  value: 'No',
                                  groupValue: _electrifiedValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _electrifiedValue = value;
                                    });
                                  },
                                ),
                                const Text('No'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Text('LPG:'),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'Yes',
                                  groupValue: _lpgValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _lpgValue = value;
                                    });
                                  },
                                ),
                                const Text('Yes'),
                                Radio<String>(
                                  value: 'No',
                                  groupValue: _lpgValue,
                                  onChanged: (value) {
                                    setState(() {
                                      _lpgValue = value;
                                    });
                                  },
                                ),
                                const Text('No'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Family Member Fields
                        ...List.generate(membersCount, (index) {
                          return Column(
                            children: [
                              TextFormField(
                                controller: _memberNameControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Member ${index + 1} Name',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the member name';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _memberAgeControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Member ${index + 1} Age',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the member age';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _memberOccupationControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Member ${index + 1} Occupation',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the member occupation';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _memberUIDControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Member ${index + 1} UID No',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the member UID No';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }),

                        // Add Member Button
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  membersCount++;
                                  _memberNameControllers.add(TextEditingController());
                                  _memberAgeControllers.add(TextEditingController());
                                  _memberOccupationControllers.add(TextEditingController());
                                  _memberUIDControllers.add(TextEditingController());
                                });
                              },
                              child: const Text('Add Member'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (membersCount > 0) {
                                  setState(() {
                                    membersCount--;
                                    _memberNameControllers.removeLast();
                                    _memberAgeControllers.removeLast();
                                    _memberOccupationControllers.removeLast();
                                    _memberUIDControllers.removeLast();
                                  });
                                }
                              },
                              child: const Text('Remove Member'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _isEditing
                              ? () {
                                  if (_editingCardId != null) {
                                    _updateCard(_editingCardId!);
                                  }
                                }
                              : _addCard,
                          child: Text(_isEditing ? 'Update Card' : 'Submit Card'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
