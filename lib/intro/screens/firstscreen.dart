import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:erationshop/admin/screens/admin_login.dart';
import 'package:erationshop/owner/screens/login1_screen.dart';
import 'package:erationshop/user/screens/login_screen.dart';

class IntroPage extends StatefulWidget {
  @override
  _IntroPageState createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();
    // No need to wait 5 seconds, the "Login as" button will be visible immediately
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,  // Handles back button press
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color.fromARGB(220, 255, 255, 255)], // White to light brown gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 150, // Lottie size
                        width: 150, // Lottie size
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Circular shape
                          border: Border.all(
                            color: const Color.fromARGB(255, 173, 111, 4),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: Lottie.asset(
                            'asset/logo.json', 
                            fit: BoxFit.cover, // Ensures Lottie fits in the circular shape
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'E-RATION',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showLoginPopup();
                  },
                  child: Text('Login as', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 183, 178, 173),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 21, 21, 21)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to show the dialog for selecting user type
  void _showLoginPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 255, 255, 254),
          title: Text('LOGIN AS....'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _userTypeButton('Admin', _navigateToAdmin),
              _userTypeButton('Distributer', _navigateToOwner),
              _userTypeButton('Customer', _navigateToCustomer),
            ],
          ),
        );
      },
    );
  }

  // Function to create a button for selecting user type
  Widget _userTypeButton(String userType, Function onPressed) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context); // Close the dialog immediately
        onPressed(); // Navigate to respective page
      },
      child: Text(userType),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 213, 205, 200),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        textStyle: TextStyle(fontSize: 18, color: Colors.white),
      ),
    );
  }

  void _navigateToAdmin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Admin_Login();
    }));
  }

  void _navigateToOwner() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Login1_Screen();
    }));
  }

  void _navigateToCustomer() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Login_Screen();
    }));
  }

  // Function to handle back button press and close the app
  Future<bool> _onWillPop() async {
    // Close the app when back button is pressed
    SystemNavigator.pop();  // Close the app
    return Future.value(false);  // Return false so that the default back button behavior doesn't occur
  }
}
