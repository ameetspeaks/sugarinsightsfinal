import 'package:flutter/material.dart';
import 'lib/screens/health/log_medication_screen.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Test',
      home: Scaffold(
        appBar: AppBar(title: Text('Route Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/log-medication');
            },
            child: Text('Test Log Medication Route'),
          ),
        ),
      ),
      routes: {
        '/log-medication': (context) => LogMedicationScreen(),
      },
    );
  }
} 