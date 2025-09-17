import 'package:flutter/material.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  // Configurazioni globali della libreria
  AquaConfig.setImageRefreshSeconds(15); // Refresh immagini ogni 15 secondi
  AquaConfig.setDefaultLocation('https://staging.fantasanremo.com'); // Location per tracking
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aqua Platform Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aqua Platform Test')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Zona 11346', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            AquaAdWidget(zoneId: '11346'),
            
            SizedBox(height: 32),
            
            Text('Zona 11562', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            AquaAdWidget(zoneId: '11562'),
          ],
        ),
      ),
    );
  }
}