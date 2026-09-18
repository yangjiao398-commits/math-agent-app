import 'package:flutter/material.dart';

class LegalDocPage extends StatelessWidget {
  const LegalDocPage({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(body, style: const TextStyle(height: 1.65, fontSize: 15)),
        ],
      ),
    );
  }
}
