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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              child: Text(body, style: const TextStyle(height: 1.75, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
