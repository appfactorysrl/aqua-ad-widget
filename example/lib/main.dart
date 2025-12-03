import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

void main() {
  // Configurazioni globali della libreria
  AquaConfig.setDefaultAdRefreshSeconds(15); // Refresh immagini ogni 15 secondi
  AquaConfig.setDefaultLocation(
      'https://staging.fantasanremo.com'); // Location per tracking

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: const Text('Aqua Platform Test',
            style: TextStyle(color: Colors.white)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 16),
          child: Column(
            children: [
              Text('Zona 11346 - Width 300, Ratio 16:9',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 300,
                ratio: 16 / 9,
                borderRadius: 12,
              ),
              SizedBox(height: 32),
              Text('Zona 11346 - Width 250, Ratio 4:3',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 250,
                ratio: 4 / 3,
              ),
              SizedBox(height: 32),
              Text('Zona 11346 - Full Width, Ratio 2:1',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                ratio: 2 / 1,
                borderRadius: 8,
              ),
              SizedBox(height: 40),
              Divider(thickness: 2),
              Text('ESEMPI CON AUTOGROW',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 20),
              Text('Zona 11346 - Width 300, AutoGrow',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 300,
                autoGrow: true,
              ),
              SizedBox(height: 32),
              Text('Zona 11346 - Width 250, AutoGrow',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 250,
                autoGrow: true,
                borderRadius: 16,
              ),
              SizedBox(height: 32),
              Text('Zona 11346 - Full Width, AutoGrow',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                autoGrow: true,
              ),
              SizedBox(height: 40),
              Divider(thickness: 2),
              Text('ESEMPIO CAROUSEL',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 20),
              Text('Zona 11346 - Carousel con 2 AD',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 350,
                ratio: 16 / 9,
                adCount: 2,
                borderRadius: 24,
              ),
              SizedBox(height: 32),
              Text('Zona 11346 - Carousel AUTO (fino a 5 AD)',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 8),
              AquaAdWidget(
                zoneId: 11346,
                width: 300,
                ratio: 16 / 9,
                adCount: 'auto',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
