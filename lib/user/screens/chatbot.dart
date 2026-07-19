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
"instruction"={"system_prompt"  : "Your name is E-Ration AI. your aim is to assist the user for the user_input . this is the system instruction and i provide app details in app_details. you can understand the app details from there. you must give reply to the user_input." , "app_details": "The project is a comprehensive solution aimed at digitalizing the Ration purchasing system by combining a Flutter mobile application with a Firebase backend. This system serves as a platform for users to access and purchase ration items conveniently and securely. It allows users to register, log in, make purchases, view outlet details, and manage their accounts seamlessly. The app features a robust user interface with multiple functionalities, designed to simplify the process of purchasing ration items and interacting with the shop owners. By using Firebase Firestore, all essential data, including user details, purchase history, ration card details, and feedback, is stored securely on the backend.

The user journey starts with registration. To begin, users can click the 'Sign Up' button, where they are required to enter essential details such as their ration card number, email, owner's name, and password. Verification is done by validating these details, and once the registration process is complete, the user can proceed to the login page. It is important to note that each ration card can only be linked to a single account, ensuring that one account corresponds to one ration card. This system prevents duplicate accounts and maintains the integrity of the user database. The registration process is built to be quick and secure, leveraging Firebase for backend storage and verification.

Once the user has successfully registered and logged in, they can proceed to explore the features provided within the app. The primary goal of the app is to allow users to purchase ration items monthly, and this is facilitated through the 'Purchase' button available on the home page. After clicking this button, the user is redirected to the item display page, where the available ration items are shown based on the user's registered ration card. The user can browse through the available products and add items to their cart. Once all the items are selected, the user can proceed to the payment section, where they can securely pay for the ration items via online payment methods.

After a successful transaction, the user is able to view the details of the purchased items at the bottom of the purchase page. A key feature here is the 'Purchased' status, which initially shows as 'Not Purchased'. Once the shop owner processes the purchase and confirms the availability of the ration items, the status is updated to 'Purchased'. This feature ensures transparency between the user and the shop, providing clarity on the current state of the order. Additionally, the app enforces a restriction that users can only purchase items once a month. This ensures that ration distribution is managed effectively and helps avoid misuse of the system. Once the items are purchased in the current month, the user can only make another purchase the following month, subject to availability.

Apart from purchasing items, the app also allows users to interact with shop information through the 'Outlet' page. Here, users can view essential details about the shop, including the store address, location, and contact information. This feature ensures that users are well-informed about the shop and can easily locate it when needed. Additionally, users have the opportunity to rate the shop, providing valuable feedback on the services provided. This helps improve the overall experience for both the shop and the users, fostering transparency and trust within the app.

Users can manage their account information through the profile section. By clicking on the profile icon located in the top right corner of the home page, users can access and view their personal details, including name, email, and ration card number. However, the registration process is only completed if the ration card owner’s face is successfully verified .This section also allows users to update their information, ensuring that their profile remains up-to-date. Additionally, users can view their ration card details by clicking the dedicated card page within the app, making it easy for them to keep track of their account and associated ration card information.

The app also provides a notification feature, where users can view updates and announcements from the admin. These notifications could include important information about the app, such as changes in policies, special offers, or system maintenance. By keeping users informed, the app ensures that they are always up to date with any relevant changes or news.

Another vital feature of the app is the Feedback Page. This section allows users to provide feedback on their experience with the app, the product, and the services provided by the ration shop. Users can share their opinions, suggestions for improvements, or concerns regarding the app's functionality or the shop’s services. The app also provides an email address and phone number for users to contact in case further assistance is needed, ensuring that any issues are promptly addressed.

Security is also a top priority within the app. In case users forget their password, the app offers a convenient password recovery feature. By clicking the 'Forgot Password' link on the login page, users can initiate the process of resetting their password. The system will send an OTP to the user's registered email address, which they must verify to complete the password reset process. Once the OTP is verified, the user can set a new password and log in again with the updated credentials.

Through its integration with Firebase, the app ensures that user data, transaction history, and feedback are stored securely, enabling smooth and efficient management of all user interactions. The combination of Flutter for the frontend and Firebase for the backend makes the app scalable, reliable, and easy to maintain, offering an excellent user experience for managing ration purchases and shop interactions.

This digital solution transforms the traditional ration purchasing system into an easy-to-use, transparent, and secure platform. By providing users with all the necessary tools to manage their ration purchases, view shop details, interact with the system, and provide feedback, the app aims to revolutionize the way ration items are distributed and accessed. The app not only improves convenience for the users but also enables shop owners and admins to efficiently manage transactions and provide better services, contributing to a more effective ration distribution system. "}''';

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