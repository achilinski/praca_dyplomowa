import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatPage extends StatefulWidget {
  final WebSocketChannel channel;

  ChatPage({Key? key, required this.channel}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  User? _user = FirebaseAuth.instance.currentUser;
  String? _username;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _username = _user?.email;

    widget.channel.stream.listen(
      (message) {
        print('Message received from server: $message');
        try {
          final decodedMessage = json.decode(message);
          _addMessage(decodedMessage);
          _scrollToBottom();
        } catch (e) {
          print('Error decoding message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed');
      },
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  void _addMessage(Map<String, dynamic> decodedMessage) {
    DateTime timestamp = DateTime.tryParse(decodedMessage['timestamp']) ?? DateTime.now();
    setState(() {
      // Add a timestamp indicator if more than an hour has passed
      if (_messages.isNotEmpty) {
        DateTime lastMessageTime = _messages.last['timestamp'];
        if (timestamp.difference(lastMessageTime).inHours >= 1) {
          _messages.add({
            'type': 'timestamp',
            'timestamp': timestamp,
          });
        }
      }
      _messages.add({
        'type': 'message',
        'username': decodedMessage['username'] ?? 'Unknown',
        'message': decodedMessage['message'] ?? '',
        'timestamp': timestamp,
      });
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      widget.channel.sink.add(json.encode({
        'message': _controller.text,
        'username': _username,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      // _addMessage({
      //   'username': _username,
      //   'message': _controller.text,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
      _controller.clear();
      _scrollToBottom();
    }
  }

  String formatDate(DateTime timestamp) {
    return DateFormat('MMM dd, yyyy, hh:mm a').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Chat Room')),
      // backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        if (msg['type'] == 'timestamp') {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                formatDate(msg['timestamp']),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return MessageBubble(
                            message: msg['message'],
                            username: msg['username'],
                            isUserMessage: msg['username'] == _username,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      hintStyle: TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.redAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final String username;
  final bool isUserMessage;

  MessageBubble({required this.message, required this.username, required this.isUserMessage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isUserMessage ? Colors.redAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(12).copyWith(
            topLeft: Radius.circular(isUserMessage ? 12 : 0),
            topRight: Radius.circular(isUserMessage ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUserMessage)
              Text(
                username,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              message,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
