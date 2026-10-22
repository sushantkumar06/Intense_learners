import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String label;

  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Text(
          'Coming soon',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
