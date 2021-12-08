import 'package:flutter/material.dart';
import 'package:spotter/views/welcome_view.dart';
import 'package:spotter/views/map_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spotter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => WelcomeView(),
        '/mapview': (context) => mapView()
      }
    );
  }
}