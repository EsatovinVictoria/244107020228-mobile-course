import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.school, size: 72),
            SizedBox(height: 16),
            Text('Esatovin Ebenhaezer Victoria', style: TextStyle(fontSize: 24)),
            Text('NIM: 244107020228', style: TextStyle(fontSize: 16)),
            Text('Kelas: 3H', style: TextStyle(fontSize: 16)),
            Text('\nPemrograman Mobile — Minggu 1'),
            Text('\nSaya sedang mengerjakan tugas :D')
          ]),
        ),
      ),
    );
  }
}