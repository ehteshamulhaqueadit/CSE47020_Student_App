import 'package:flutter/material.dart';

class SamplePage extends StatelessWidget {
  const SamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sample Page')),
      body: const Center(child: Text('Welcome to Sample Page')),
    );
  }
}
