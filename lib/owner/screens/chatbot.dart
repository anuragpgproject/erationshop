import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'dart:developer';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  AiChatPageState createState() => AiChatPageState();
}

class AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;

  List<Map<String, dynamic>>? usersPosts;

  @override
  void initState() {
    super.initState();
  }

  final instructions = '''
"instruction"={"system_prompt"  : "Your name is E-Ration AI. your aim is to assist the user for the user_input . this is the system instruction and i provide app details in app_details. you can understand the app details from there. you must give reply to the user_input." , "app_details": "The Ration Shop Owner plays a crucial role in the efficient operation of the E-Ration app, acting as the primary point of contact for managing shop-related activities, order processing, stock management, and communication with both the admin and the users. The owners responsibilities within the app are diverse, involving various functions ranging from profile management and password recovery to managing customer orders and providing feedback. This detailed overview covers the full scope of an owners functionalities within the app and highlights the apps user-friendly features designed to simplify daily operations.The Ration Shop Owner's journey within the app begins with registration, which is handled by the Admin. During this phase, the Admin creates the owner’s account, entering essential shop details such as the shop’s name, location, and contact information. At the time of registration, the Admin also assigns the initial credentials to the owner. While the Admin takes care of the registration process, the owner retains full control over their profile after logging into the app. They can view and edit their personal details, including their name, phone number, email, and shop information. A crucial feature in the profile section is the ability for the owner to change their password. This is a security measure that ensures the owner’s account remains protected. If the owner ever forgets their password, they can easily reset it by following the forgot password flow, which involves receiving an OTP (One-Time Password) to their registered email address. After OTP verification, the owner is allowed to set a new password, ensuring that account security remains uncompromised.

One of the key features ensuring security within the app is the forgot password option, which is vital in case the owner forgets their credentials. Upon selecting this option, the owner receives a verification email containing an OTP, which must be entered to authenticate the password change. Once the OTP is successfully verified, the owner can reset their password. This system ensures that only the rightful owner can regain access to their account, thereby preventing unauthorized access and protecting sensitive shop and user data.

In addition to managing their profile, the Ration Shop Owner has the critical task of handling orders. The app allows the owner to place orders on behalf of users who do not have an E-Ration account or the app installed. This feature is particularly useful for ensuring that all eligible users, regardless of their access to the app, can receive ration items from the shop. The process involves entering the user’s ration card number and the linked mobile number, followed by an OTP sent to the mobile number. After verifying the OTP, the owner can proceed to complete the purchase order.

Another important responsibility of the owner is stock management. The app offers the owner a dedicated Stock Page, where they can update the current stock of ration items available in the shop. This feature ensures that the shop maintains accurate inventory levels and prevents stockouts or overselling, which could lead to dissatisfaction among users.

The app also facilitates seamless communication between the owner and the admin. The Enquiry Page allows the owner to submit queries or complaints to the admin, ensuring that issues are addressed promptly. Whether it's a stock-related issue, technical difficulty, or request for assistance, the enquiry feature fosters a transparent line of communication.

Moreover, the app encourages the Ration Shop Owner to provide valuable feedback on the app’s features and services. Through the Feedback Page, owners can submit suggestions for improvements, highlight any bugs they encounter, or share general comments on their user experience. This feedback helps in continuously improving the app’s functionality and addressing user concerns.

The Notification Page ensures that the owner stays updated on important announcements and news from the admin. These notifications could include updates on new policies, changes in regulations, special offers, or system maintenance. Keeping the owner informed is essential for ensuring smooth operations and compliance with any new guidelines or changes.

Additionally, the Purchase Confirmation Page is where the owner can manage all orders placed by users. It offers a comprehensive view of each order, including the order details and payment status. The owner has the ability to search for specific orders by their Order ID, making it easier to track and manage requests. Once an order is confirmed and the ration items have been distributed, the owner can mark the order status as "Purchased". This page helps maintain accurate records of each transaction, ensuring that the inventory and customer orders are properly synchronized.

The Ration Shop Owner in the E-Ration app is entrusted with multiple essential tasks that help maintain the efficiency and success of the shop. From managing orders and stock to handling personal profiles and communication with the admin, the app provides a comprehensive suite of tools designed to simplify the owner’s responsibilities. By offering secure password management, easy communication channels, and robust order tracking, the app ensures that the owner can effectively serve users, manage inventory, and keep the shop running smoothly. Ultimately, the Ration Shop Owner’s role within the E-Ration app is vital for maintaining the operational flow of the shop and ensuring a seamless experience for all users. "}''';

  void _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({'role': 'user', 'message': userMessage});
      _isLoading = true;
    });

    String modifiedUserInput =
        '''$instructions,  "user_input": "$userMessage"''';

    try {
      final gemini = Gemini.instance;

      final conversation = [
        ..._chatHistory.map(
          (msg) => Content(
            parts: [Part.text(msg['message']!)],
            role: msg['role'],
          ),
        ),
        Content(
          parts: [Part.text(modifiedUserInput)],
          role: 'user',
        ),
      ];
      final response = await gemini.chat(conversation);
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'role': 'model',
            'message': response?.output ?? 'No response received',
          });
        });
      }
    } catch (e) {
      log('Error in chat: $e');
      if (mounted) {
        setState(() {
          _chatHistory.add({
            'role': 'error',
            'message':
                'Response not loading. Please try again or check your internet connection.',
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMessageBubble(String message, String role,
      {bool isLoading = false}) {
    bool isUser = role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 18.0),
        decoration: BoxDecoration(
          color: isUser
              ? const Color.fromARGB(255, 48, 77, 159)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
            bottomLeft: isUser ? const Radius.circular(20.0) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20.0),
          ),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color.fromARGB(255, 39, 36, 36).withOpacity(0.1),
              offset: const Offset(0, 2),
              blurRadius: 4.0,
            ),
          ],
        ),
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                message,
                style: TextStyle(
                  fontSize: 16.0,
                  color: isUser ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemBuilder: (context, index) {
        if (index == _chatHistory.length && _isLoading) {
          return _buildMessageBubble('', 'model', isLoading: true);
        }
        final message = _chatHistory[index];
        return _buildMessageBubble(message['message']!, message['role']!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 255, 255),
                Color.fromARGB(255, 255, 255, 255),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 0.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage('asset/logo.jpg'),
                backgroundColor: Color.fromARGB(255, 0, 0, 0),
                radius: 25,
              ),
              SizedBox(width: 10),
              Text(
                'E-Ration AI',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _chatHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'Start a conversation with E-Ration AI',
                          style: TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      )
                    : _buildChatList(),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: TextStyle(
                                color: const Color.fromARGB(255, 0, 0, 0)),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 152, 144, 144),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 0, 0, 0)),
                            ),
                          ),
                          minLines: 1,
                          maxLines: 5,
                          onSubmitted: (_) {
                            final message = _controller.text;
                            _controller.clear();
                            _sendMessage(message);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color.fromARGB(255, 9, 36, 82),
                        ),
                        onPressed: () {
                          final message = _controller.text;
                          _controller.clear();
                          _sendMessage(message);
                        },
                        splashColor: Colors.blueAccent.withOpacity(0.3),
                        splashRadius: 25,
                      ),
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