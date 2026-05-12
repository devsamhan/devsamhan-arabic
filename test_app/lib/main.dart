import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const ArabicTestApp());

class ArabicTestApp extends StatelessWidget {
  const ArabicTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arabic Libraries Test',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
