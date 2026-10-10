import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman')),
      body: Center(
        child: Text('Pengumuman ID: $id', style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
