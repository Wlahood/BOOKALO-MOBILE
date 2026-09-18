import 'package:flutter/material.dart';
import 'screens/app_shell.dart';
import 'services/link_router.dart';

void main() {
  runApp(const BookaloApp());
}

class BookaloApp extends StatefulWidget {
  const BookaloApp({super.key});

  @override
  State<BookaloApp> createState() => _BookaloAppState();
}

class _BookaloAppState extends State<BookaloApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final LinkRouter _links;

  @override
  void initState() {
    super.initState();
    _links = LinkRouter(_navigator);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _links.start();
    });
  }

  @override
  void dispose() {
    _links.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Bookalo',
      theme: ThemeData(useMaterial3: true),
      home: const AppShell(),
    );
  }
}
