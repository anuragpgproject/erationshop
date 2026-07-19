import 'package:erationshop/admin/screens/admin_allowp.dart';
import 'package:erationshop/admin/screens/all_orders.dart';
import 'package:erationshop/admin/screens/cardcategories.dart';
import 'package:erationshop/admin/screens/chatbot.dart';
import 'package:erationshop/admin/screens/faceaddadmin.dart';
import 'package:erationshop/admin/screens/faceaddcustomer.dart';
import 'package:erationshop/admin/screens/faceaddddistributer.dart';
import 'package:erationshop/admin/screens/feedback_show.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'admin_product.dart'; // Import your AdminProductPage
import 'admin_profile.dart';
import 'admin_stoke.dart';
import 'admin_card.dart';
import 'admin_notification.dart';
import 'admin_shop.dart';
import 'admin.converse.dart';
import 'package:flutter/services.dart'; // Import to use SystemNavigator.pop()

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _cards = [
    {
      'title': 'Stock',
      'icon': Icons.inventory,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Keep track of Ration Shops Stocks and add to it',
      'image': 'asset/stock.jpg',
      'page': StockPage(), // Navigation target
    },
    
    {
      'title': 'Card',
      'icon': Icons.credit_card,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Manage Ration card-related operations.',
      'image': 'asset/card.jpg',
      'page': AddCardPage(), // Navigation target
    },
    {
      'title': "Distributer's Enquiry",
      'icon': Icons.chat,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Communicate with Distributers.',
      'image': 'asset/stock.jpg',
      'page': ConversePage(), // Navigation target
    },
    {
      'title': 'Card Categories',
      'icon': Icons.credit_card,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'View and manage Categories of Cards.',
      'image': 'asset/card.jpg',
      'page': CategoryPage(), // Navigation target
    },
    {
      'title': 'Notifications',
      'icon': Icons.notifications,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'View and manage important notifications.',
      'image': 'asset/notification.jpg',
      'page': AdminNotificationPage(), // Navigation target
    },
    {
      'title': 'Add Ration-Shops',
      'icon': Icons.shop,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Add new Ration-Shop and Distributer details.',
      'image': 'asset/outlet.jpg',
      'page': AdminShopPage(), // Navigation target for AdminShopPage
    },
    {
      'title': 'Face ID add',
      'icon': Icons.camera,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Add /update the Face Id of Distributer.',
      'image': 'asset/camera.jpeg',
      'page': AdminFaceCaptureForShopScreen(), // Navigation target for AdminShopPage
    },
    {
      'title': 'Face ID add',
      'icon': Icons.camera,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Add / update the Face Id of Admin.',
      'image': 'asset/camera.jpeg',
      'page': AdminFaceCaptureScreen(), // Navigation target for AdminShopPage
    },
     {
      'title': 'Face ID add',
      'icon': Icons.camera,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Add / update the Face Id of Card Owners.',
      'image': 'asset/camera.jpeg',
      'page': AdminFaceCaptureCustomer(), 
    },
    {
      'title': 'All Orders',
      'icon': Icons.shopping_cart,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'All order details of the Customer',
      'image': 'asset/purchase.jpg',
      'page': OrdersPage(), // Navigation target for AdminShopPage
    },
    {
      'title': 'Purchase Activation',
      'icon': Icons.shopping_cart,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Allow the customer to purchase items.',
      'image': 'asset/purchase.jpg',
      'page': AdminAllowPurchase(), // Navigation target for AdminShopPage
    },
    {
      'title': 'Add Product',
      'icon': Icons.add_box,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Add new products to the stock.',
      'image': 'asset/outlet.jpg',
      'page': AdminProduct(), // Navigation target for AdminProductPage
    },
    {
      'title': 'Feedbacks',
      'icon': Icons.inventory,
      'color': const Color.fromARGB(255, 0, 0, 0),
      'description': 'Keep track of Customer Feedbacks.',
      'image': 'asset/stock.jpg',
      'page': FeedbackGraphPage(), // Navigation target
    },

  ];

  // Function to handle infinite scrolling
  void _onPageChanged(int index) {
    if (index == _cards.length - 1) {
      _pageController.jumpToPage(0); // Reset to first page
    } else if (index == 0) {
      _pageController.jumpToPage(_cards.length - 0); // Go to the second last page
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.toInt();
      if (page != null) {
        _onPageChanged(page);
      }
    });
  }

  void _onCardTapped(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()), // Navigate to Profile screen
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
          backgroundColor: Colors.black, // Set background color to black
          automaticallyImplyLeading: false, // Remove default back button
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the title
            children: [
              // Logo on the leftmost corner
              Padding(
                padding: const EdgeInsets.only(left: 8.0), // Padding to move logo slightly from left
                child: ClipOval(
                  child: Image.asset(
                    'asset/logo.jpg', // Path to your logo asset
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Title in the center
              Expanded(
                child: Center(
                  child: Text(
                    'E-RATION (ADMIN)', // Centered title
                    style: GoogleFonts.merriweather(
                      color: Colors.white, // Set text color to white
                      fontWeight: FontWeight.bold,
                      fontSize: 22.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Profile icon at the rightmost corner
            IconButton(
              icon: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color.fromARGB(255, 0, 0, 0)),
              ),
              onPressed: _goToProfile, // Navigate to Profile screen
            ),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 255, 255, 255),
                    const Color.fromARGB(255, 255, 255, 255),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 30), // Give some space after app bar
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: null, // Infinite pages
                          itemBuilder: (context, index) {
                            final card = _cards[index % _cards.length];
                            return _buildPageCard(card);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: SmoothPageIndicator(
                          controller: _pageController,
                          count: _cards.length,
                          effect: ExpandingDotsEffect(
                            dotWidth: 10,
                            dotHeight: 10,
                            activeDotColor: const Color.fromARGB(255, 0, 0, 0),
                            dotColor: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

  Widget _buildPageCard(Map<String, dynamic> card) {
    return Center(
      child: GestureDetector(
        onTap: () => _onCardTapped(card['page']),
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
                offset: Offset(0, 10),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(card['icon'], size: 60, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    card['title'],
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      card['description'],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
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
