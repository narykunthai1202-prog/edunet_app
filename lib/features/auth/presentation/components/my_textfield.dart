import 'package:flutter/material.dart';

class MyTextfield extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final bool obscureText;
  final String? text;

  const MyTextfield({
    super.key,
    this.controller,
    required this.hintText,
    required this.obscureText,
    this.text,
  });

  @override
  State<MyTextfield> createState() => _MyTextfieldState();
}

class _MyTextfieldState extends State<MyTextfield> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();

    if (_controller.text.isEmpty && widget.text != null) {
      _controller.text = widget.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: widget.obscureText,
      decoration: InputDecoration(
        hintText: widget.hintText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
