import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../cubits/post_cubit.dart';

class MentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<List<String>> onTaggedUsersChanged;
  final int maxLines;
  final InputDecoration? decoration;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.onTaggedUsersChanged,
    this.maxLines = 5,
    this.decoration,
  });

  @override
  State<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends State<MentionTextField> {
  List<Map<String, dynamic>> _suggestions = [];
  final Map<String, String> _selectedUsers = {};
  bool _searching = false;
  String? _searchError;
  String? _activeQuery;
  int _searchVersion = 0;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final text = widget.controller.text;
    final removedUserIds = _selectedUsers.entries
        .where((entry) => !text.contains('@${entry.value}'))
        .map((entry) => entry.key)
        .toList();
    if (removedUserIds.isNotEmpty) {
      for (final uid in removedUserIds) {
        _selectedUsers.remove(uid);
      }
      widget.onTaggedUsersChanged(_selectedUsers.keys.toList());
    }

    final selection = widget.controller.selection;

    if (!selection.isValid || selection.baseOffset < 0) return;

    final cursor = selection.baseOffset;
    final beforeCursor = text.substring(0, cursor);
    final match = RegExp(r'@([a-zA-Z0-9_. ]*)$').firstMatch(beforeCursor);

    if (match == null) {
      if (_activeQuery != null || _suggestions.isNotEmpty) {
        _searchDebounce?.cancel();
        setState(() {
          _activeQuery = null;
          _suggestions = [];
          _searching = false;
          _searchError = null;
          _searchVersion++;
        });
      }
      return;
    }

    final query = (match.group(1) ?? '').trimLeft();

    // Wait for at least one character after @.
    if (query.isEmpty) {
      _searchDebounce?.cancel();
      setState(() {
        _activeQuery = '';
        _suggestions = [];
        _searching = false;
        _searchError = null;
        _searchVersion++;
      });
      return;
    }

    if (query == _activeQuery) return;

    _activeQuery = query;
    _searchDebounce?.cancel();
    _searchVersion++;
    setState(() {
      _suggestions = [];
      _searching = false;
      _searchError = null;
    });
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _searchUsers(query),
    );
  }

  Future<void> _searchUsers(String query) async {
    final version = ++_searchVersion;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      setState(() {
        _searching = false;
        _searchError = 'Sign in to mention another user.';
      });
      return;
    }

    setState(() {
      _searching = true;
      _searchError = null;
    });

    try {
      final results = await context.read<PostCubit>().searchUsersForMention(
        query,
        uid,
      );

      if (!mounted || version != _searchVersion) return;

      setState(() {
        _suggestions = results;
        _searching = false;
        _searchError = null;
      });
    } catch (error) {
      if (!mounted || version != _searchVersion) return;
      setState(() {
        _suggestions = [];
        _searching = false;
        _searchError = 'Could not search users: $error';
      });
    }
  }

  void _selectUser(Map<String, dynamic> user) {
    final uid = user['uid'] as String;
    final name = user['name'] as String;

    final text = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursor);
    final afterCursor = text.substring(cursor);

    final match = RegExp(r'@([a-zA-Z0-9_. ]*)$').firstMatch(beforeCursor);

    if (match == null) return;

    final start = match.start;
    final replacement = '@$name ';

    widget.controller.value = TextEditingValue(
      text: beforeCursor.substring(0, start) + replacement + afterCursor,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );

    _selectedUsers[uid] = name;

    widget.onTaggedUsersChanged(_selectedUsers.keys.toList());

    setState(() {
      _activeQuery = null;
      _suggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          minLines: 2,
          decoration:
              widget.decoration ??
              const InputDecoration(
                hintText: 'What do you want to share? Type @ to tag a friend',
                border: InputBorder.none,
              ),
        ),
        if (_searching)
          const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          ),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final user = _suggestions[index];
                final imageUrl = user['profileImageUrl'] as String? ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: imageUrl.isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user['name'] as String),
                  onTap: () => _selectUser(user),
                );
              },
            ),
          ),
        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _searchError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
