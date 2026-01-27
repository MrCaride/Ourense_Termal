import 'package:flutter/material.dart';

void main() {
  runApp(const OurenseTermalApp());
}

class OurenseTermalApp extends StatelessWidget {
  const OurenseTermalApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OurenseTermal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ourense Termal'),
      ),
      body: const Center(
        child: Text(
          'Bienvenido al turismo termal gamificado',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
