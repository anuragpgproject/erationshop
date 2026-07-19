import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:erationshop/intro/screens/firstscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? emailAdmin;
  bool isLoading = true;
  bool isPasswordChanging = false;  // Track visibility of password change fields
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _newAdminNameController = TextEditingController();
  TextEditingController _newAdminEmailController = TextEditingController();
  TextEditingController _newAdminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmailFromPrefs();
  }

  // Load email from SharedPreferences (already loaded in main.dart)
  Future<void> _loadEmailFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      emailAdmin = prefs.getString('email');
      print("Loaded email from SharedPreferences: $emailAdmin"); // Debug print
      isLoading = false;
    });
  }

  // Method to update admin password in Firestore
  Future<void> _updatePassword() async {
    try {
      String newPassword = _passwordController.text.trim();
      if (newPassword.isNotEmpty && emailAdmin != null) {
        // Update the password field in Firestore for the admin
        await FirebaseFirestore.instance
            .collection('Admin')
            .where('email', isEqualTo: emailAdmin)
            .limit(1)
            .get()
            .then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            var doc = querySnapshot.docs.first;
            doc.reference.update({'password': newPassword});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Password updated successfully')),
            );
          }
        });

        _passwordController.clear();
        setState(() {
          isPasswordChanging = false; // Hide password fields after update
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: $e')),
      );
    }
  }

  // Method to add new admin to Firestore
  Future<void> _addNewAdmin() async {
    try {
      String name = _newAdminNameController.text.trim();
      String email = _newAdminEmailController.text.trim();
      String password = _newAdminPasswordController.text.trim();

      if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
        // Add new admin to Firestore
        await FirebaseFirestore.instance.collection('Admin').add({
          'name': name,
          'email': email,
          'password': password,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New admin added successfully')),
        );

        _newAdminNameController.clear();
        _newAdminEmailController.clear();
        _newAdminPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill in all fields')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding new admin: $e')),
      );
    }
  }

  // Logout function to clear SharedPreferences and navigate to IntroPage
  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');  // Remove the stored email and other data
    // You can also remove other data such as 'card_no', 'shop_id' if applicable
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => IntroPage()),  // Navigate to IntroPage
    );
  }

  @override
  Widget build(BuildContext context) {
    // If still loading email from prefs, show a loading indicator
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Admin Profile", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold,color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If email is null, show message to indicate no email found
    if (emailAdmin == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Admin Profile", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold,color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          iconTheme: IconThemeData(color: Colors.white),
          elevation: 0,
        ),
        body: Center(
          child: Text(
            'No admin email found. Please log in again.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    print("Searching for admin with email: $emailAdmin"); // Debug print

    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Profile", style: GoogleFonts.merriweather(fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 0, 0, 0),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,  // Call the logout method when pressed
          ),
        ],
      ),
      body: Container(
        height: double.infinity, // Ensure the gradient fills the entire screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [ Color.fromARGB(255, 255, 255, 255), Color.fromARGB(255, 255, 255, 255)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Admin') // Admin collection
              .where('email', isEqualTo: emailAdmin) // Match the stored email
              .limit(1) // Fetch one matching document
              .snapshots(),
          builder: (context, snapshot) {
            // Show loading indicator while fetching data from Firestore
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            // Handle Firestore error
            if (snapshot.hasError) {
              return Center(child: Text('Error :${snapshot.error}'));
            }

            // If no data found for this email
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No admin profile found for this email.'));
            }

            // Extract profile data from Firestore
            final profile = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            final String name = profile['name'] ?? 'N/A';
            final String email = profile['email'] ?? 'N/A';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image Section
                    Center(
                      child: CircleAvatar(
                        radius: 80,
                        backgroundImage: AssetImage('asset/profilepic.jpg'), // Replace with your image path
                      ),
                    ),
                    SizedBox(height: 20),

                    // Profile information sections
                    _buildProfileInfoRow("Name", name),
                    SizedBox(height: 20),
                    _buildProfileInfoRow("Email", email),
                    SizedBox(height: 20),

                    // Change Password Section
                    _buildChangePasswordSection(),
                    SizedBox(height: 40),

                    // Add New Admin Section
                    _buildAddNewAdminSection(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper widget to build each profile info row
  Widget _buildProfileInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 208, 207, 206),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Change password section
  Widget _buildChangePasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: () {
            setState(() {
              isPasswordChanging = !isPasswordChanging;  // Toggle visibility
            });
          },
          child: Text(isPasswordChanging ? "Cancel Change Password" : "Change Password" ,style: TextStyle(color: Colors.red),),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 208, 207, 206)),
          ),
        ),
        SizedBox(height: 10),
        if (isPasswordChanging) ...[  
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: "New Password",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updatePassword,
            child: Text("Update Password",style: TextStyle(color: const Color.fromARGB(255, 25, 116, 4)),),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 208, 207, 206)),
            ),
          ),
        ],
      ],
    );
  }

  // Add new admin section
  Widget _buildAddNewAdminSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Add New Admin", style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        TextField(
          controller: _newAdminNameController,
          decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _newAdminEmailController,
          decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
        ),
        SizedBox(height: 10),
        TextField(
          controller: _newAdminPasswordController,
          obscureText: true,
          decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _addNewAdmin,
          child: Text("Add Admin",style: TextStyle(color: Colors.black),),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Color.fromARGB(255, 208, 207, 206)),
          ),
        ),
      ],
    );
  }
}
