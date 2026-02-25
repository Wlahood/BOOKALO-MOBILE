import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BookaloApp());
}

class BookaloApp extends StatelessWidget {
  const BookaloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookalo',
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
