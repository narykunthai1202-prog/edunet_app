import 'package:flutter/material.dart';
import 'chat_view.dart';

class NewChatView extends StatefulWidget {
  final String currentUserId;

  const NewChatView({
    super.key,
    required this.currentUserId,
  });

  @override
  State<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<NewChatView> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Registered contacts list
  final Map<String, String> userNames = {
    'user2': 'Shin Shoeri',
    'user3': 'Kang Taemoo',
    'user4': 'Baek Sohyun',
    'user5': 'Hong Haein',
  };

  @override
  void dispose() {
    _idController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startChat(String receiverId, String receiverName) {
  // Generate unique 1-on-1 chatId sorted alphabetically
  List<String> ids = [widget.currentUserId, receiverId]..sort();
  String generatedChatId = ids.join('_');

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => ChatView(
        currentUserId: widget.currentUserId,
        receiverId: receiverId,
        receiverName: receiverName,
        chatId: generatedChatId,
        peerId: receiverId, // <--- Add this line
      ),
    ),
  );
}

  void _showAddCustomIdDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add by User ID'),
        content: TextField(
          controller: _idController,
          decoration: const InputDecoration(
            hintText: 'Enter user ID (e.g., user2)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            onPressed: () {
              final id = _idController.text.trim();
              if (id.isNotEmpty && id != widget.currentUserId) {
                Navigator.pop(context);
                final name = userNames[id] ?? 'User ($id)';
                _startChat(id, name);
              }
            },
            child: const Text('Start Chat', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter contacts based on search query (by name or user ID)
    final filteredUsers = userNames.entries.where((entry) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      final nameMatches = entry.value.toLowerCase().contains(query);
      final idMatches = entry.key.toLowerCase().contains(query);
      return nameMatches || idMatches;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Message',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Custom ID Action Row
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF2563EB),
              child: Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
            ),
            title: const Text(
              'Add User by ID',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
            subtitle: const Text(
              'Start chat with any custom user ID',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: _showAddCustomIdDialog,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'CONTACTS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Contacts List
          Expanded(
            child: filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 72, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final entry = filteredUsers[index];
                      final userId = entry.key;
                      final userName = entry.value;

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
                          child: Text(
                            userName.isNotEmpty ? userName[0] : '?',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '@$userId',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                        trailing: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF2563EB),
                          size: 20,
                        ),
                        onTap: () => _startChat(userId, userName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}