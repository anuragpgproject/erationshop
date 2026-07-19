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
"instruction"={"system_prompt"  : "Your name is E-Ration AI. your aim is to assist the user for the user_input . this is the system instruction and i provide app details in app_details. you can understand the app details from there. you must give reply to the user_input." , "app_details": "The admin page in the E-Ration system is designed to provide comprehensive control over the entire digital purchasing system. The role of the admin is fundamental, as they oversee and manage all key operations of the platform. The admin is assigned their role by another higher-level admin, and once allotted, they can log in to the system. Upon logging in, the admin gains access to a specialized profile section, where they can make changes to their account details, including the ability to change their password. Additionally, this section allows the admin to add new admins, thus expanding the administration team for the platform.

A key feature for admins who may forget their password is the "Forgot Password" option available on the login page. If the admin forgets their password, the system sends an OTP (One-Time Password) to the admin's registered email address, provided the email is found within the admin's database. This ensures a secure method of resetting passwords and maintaining the integrity of the system.

In terms of managing store operations, the admin has the ability to add, edit, and view the current stock in the stores. This means the admin can keep track of inventory and ensure that the stores are properly stocked with ration items. If needed, the admin can update stock levels or make adjustments to inventory records as required. The admin also has the ability to add new shops to the system. To do so, the admin needs to enter key details such as the shop’s name, email address, location, and other relevant information to set up the new shop’s profile. Shops are displayed in a list format at the bottom of the page, and for each shop, the average rating given by users is visible. This user-generated rating system allows the admin to assess the performance and customer satisfaction level of each shop. Based on the ratings, the admin can take necessary measures to improve services or address any issues.

The admin is also tasked with managing the ration card system. They can add new cards to the system by entering the necessary card details, as well as edit or delete existing cards when required. This enables the admin to maintain an up-to-date list of ration cards within the system. Additionally, the admin is responsible for handling shop owner enquiries. These enquiries can be addressed through the "Shop Enquiry" page, where the admin can view and resolve any concerns raised by shop owners, thus facilitating smoother communication and operations.

The admin can manage card categories through the "Card Categories" page. In this section, the admin has the ability to add new categories, remove items from existing categories, or modify category details. This allows the admin to effectively organize and update the various types of ration cards available on the platform, ensuring that they are categorized correctly for easy access by users.

To communicate with users, the admin can send out notifications via the "Notification" page. These notifications can be used to inform users about important updates, changes in store policies, promotions, or any other relevant information. The ability to push notifications ensures that the admin can keep all users informed in real-time.

In addition to these management tasks, the admin can add new products to the platform via the "Add Product" page. This allows the admin to maintain a current list of ration items available for purchase by users, ensuring that the products offered are up-to-date and meet the needs of the community.

Furthermore, the admin receives feedback from both users and shop owners through the "Feedback" page. This feedback is displayed in a graphical format, with positive and negative feedback represented visually. To ensure that the feedback is analyzed in-depth, the system utilizes sentiment analysis techniques to process the feedback and categorize it as positive, neutral, or negative. This allows the admin to easily assess the overall sentiment of the platform’s users and take necessary actions based on the feedback received. By utilizing sentiment analysis, the admin can gain valuable insights into user and shop owner satisfaction and can make informed decisions to improve the platform’s operations.

In conclusion, the admin page in the E-Ration system serves as a centralized hub where all aspects of the digital ration purchasing system are managed. From managing stock and stores to handling user feedback and pushing notifications, the admin plays a vital role in maintaining the functionality and efficiency of the system. With the ability to add and edit cards, manage categories, and resolve shop owner enquiries, the admin ensures that the platform runs smoothly and provides a seamless experience for both users and shop owners."}''';

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