import 'package:erationshop/owner/screens/chatbot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import to use SystemNavigator.pop()
import 'package:erationshop/owner/screens/owner_feedback.dart';
import 'package:erationshop/owner/screens/owner_purchaseconf.dart';
import 'package:erationshop/owner/screens/owner_purchase.dart';
import 'package:erationshop/owner/screens/owner_enquiry.dart';
import 'package:erationshop/owner/screens/owner_notification.dart';
import 'package:erationshop/owner/screens/owner_outlet.dart';
import 'package:erationshop/owner/screens/owner_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final PageController _pageController = PageController();
  String? shopId; // Nullable to handle loading state

  // Cards list with navigation targets
  final List<Map<String, dynamic>> _cards = [
    {
      'title': 'Purchase',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Keep track of available inventory and supplies.',
      'image': 'asset/purchase.jpg',
      'page': OwnerPurchase(),
    },
    {
      'title': 'Outlet',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Find and Analyze the Ration Outlets.',
      'image': 'asset/outlet.jpg',
      'page': null, // Will handle separately in the logic
    },
    {
      'title': 'Purchase Confirmation',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Confirm the purchase of the User.',
      'image': 'asset/purchase.jpg',
      'page': OwnerOrdersPage(),
    },
    {
      'title': 'Enquiry',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Address and Resolve Your Complaints.',
      'image': 'asset/enquiry.jpg',
      'page': null, // Will handle separately
    },
    {
      'title': 'Notification',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'New Updates and Notifications are here.',
      'image': 'asset/notification.jpg',
      'page': OwnerNotification(),
    },
     {
      'title': 'Feedback',
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Give Feedbacks about App and Other Services.',
      'image': 'asset/feedback.jpeg',
      'page': FeedbackPage(), 
    },
    
  ];

  @override
  void initState() {
    super.initState();
    _loadShopId();
  }

  // Fetch the shopId from SharedPreferences
  Future<void> _loadShopId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      shopId = prefs.getString('shop_id');
    });
  }

  void _onCardTapped(BuildContext context, Widget? page, String title) {
    if (page != null) {
      // Navigate to the given page if it’s not null
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    } else if (shopId != null) {
      // Handle the special cases where `page` is null
      if (title == 'Outlet') {
        // Handle navigation for Outlet card
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OwnerOutletPage(shopId: shopId!),
          ),
        );
      } else if (title == 'Enquiry') {
        // Handle navigation for Enquiry card
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EnquiryPage(shopId: shopId!),
          ),
        );
      }
    } else {
      // If no shopId found, show error
      _showErrorSnackBar(context, 'No shop ID found. Please log in again.');
    }
  }

  // Navigate to owner profile page
  void _goToProfile() {
    if (shopId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(shopId: shopId!),
        ),
      );
    } else {
      _showErrorSnackBar(context, 'No shop ID found. Please log in again.');
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Handle the back button press
  Future<bool> _onWillPop() async {
    // Close the app when the back button is pressed
    SystemNavigator.pop();
    return false; // Prevent the default back navigation behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Custom back button behavior
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false, // Remove back button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the title text
            children: [
              Text(
                'E-RATION (DISTRIBUTER)', // The title in the center
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25, // Adjust size as needed
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          leading: Padding(
            padding: const EdgeInsets.all(8.0), // To add some spacing
            child: ClipOval(
              child: Image.asset(
                'asset/logo.jpg',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
              onPressed: _goToProfile,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Cards Section
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _cards.length,
                    itemBuilder: (context, index) {
                      final card = _cards[index];
                      return _buildPageCard(context, card);
                    },
                  ),
                ),

                // Dot indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: _cards.length,
                    effect: const ExpandingDotsEffect(
                      dotWidth: 10,
                      dotHeight: 10,
                      activeDotColor: Color.fromARGB(255, 12, 12, 12),
                      dotColor: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            
            // Chatbot Icon Button - Positioned at the bottom-right corner
            Positioned(
              bottom: 30,
              right: 30,
              child: IconButton(
                icon: CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  child: Icon(
                    Icons.chat,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                onPressed: () {
                  // Navigate to the chatbot page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AiChatPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build card for each item
  Widget _buildPageCard(BuildContext context, Map<String, dynamic> card) {
    return Center(
      child: GestureDetector(
        onTap: () => _onCardTapped(context, card['page'], card['title']),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: card['color'].withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  card['image'],
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.1),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    card['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      card['description'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

