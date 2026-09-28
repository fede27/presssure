import 'package:flutter/material.dart';

void main() {
  runApp(const PressSureApp());
}

class PressSureApp extends StatelessWidget {
  const PressSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PressSure',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('PressSure'),
      ),
      body: const Center(
        child: Text('Diario della pressione'),
      ),
    );
  }
}
