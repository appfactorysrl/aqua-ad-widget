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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Zona 11346 - Width 300, Ratio 16:9', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
                color: Colors.yellow.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                width: 300,
                ratio: 16/9,
              ),
            ),

            SizedBox(height: 32),

            Text('Zona 11346 - Width 250, Ratio 4:3', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                color: Colors.green.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                width: 250,
                ratio: 4/3,
              ),
            ),

            SizedBox(height: 32),

            Text('Zona 11346 - Full Width, Ratio 2:1', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 2),
                color: Colors.orange.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                ratio: 2/1,
              ),
            ),

            SizedBox(height: 40),
            Divider(thickness: 2),
            Text('ESEMPI CON AUTOGROW', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
            SizedBox(height: 20),

            Text('Zona 11346 - Width 300, AutoGrow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal, width: 2),
                color: Colors.cyan.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                width: 300,
                autoGrow: true,
              ),
            ),

            SizedBox(height: 32),

            Text('Zona 11346 - Width 250, AutoGrow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.brown, width: 2),
                color: Colors.amber.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                width: 250,
                autoGrow: true,
              ),
            ),

            SizedBox(height: 32),

            Text('Zona 11346 - Full Width, AutoGrow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.indigo, width: 2),
                color: Colors.pink.withValues(alpha: 0.3),
              ),
              child: AquaAdWidget(
                zoneId: 11346,
                autoGrow: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
