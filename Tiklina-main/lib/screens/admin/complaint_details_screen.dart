import 'package:flutter/material.dart';
import 'verification_screen.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  const ComplaintDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complaint Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Status: Collected by Company',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text('Reported on: 24 Mar 2026'),
            SizedBox(height: 20),
            Container(
              height: 150,
              color: Colors.grey.shade300,
              child: Center(child: Text('Original Photo')),
            ),
            SizedBox(height: 20),
            Container(
              height: 150,
              color: Colors.grey.shade300,
              child: Center(child: Text('Collector Proof Photo')),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VerificationScreen()),
                );
              },
              child: Text('Verify & Rate Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
