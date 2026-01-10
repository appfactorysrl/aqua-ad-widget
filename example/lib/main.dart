import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';
import 'debug_page.dart';

void main() {
  // Configurazioni globali della libreria
  AquaConfig.setDefaultAdRefreshSeconds(15);
  AquaConfig.setDefaultBaseUrl('https://delivery.ads.fantasanremo.com/asyncspc.php');
  AquaConfig.setDefaultLocation('https://fantasanremo.com');
  AquaConfig.setDefaultHideIfEmpty(true);

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
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DebugPage()),
              );
            },
          ),
        ],
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Container(
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
                Text('Zona 9 - Width 528, Ratio 16:9',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 8),
                Container(
                  width: 528,
                  height: 528 / (16 / 9),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text('Box Sopra', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(height: 8),
                AquaAdWidget(
                  zoneId: 9,
                  ratio: 1440 / 810,
                  borderRadius: 16,
                  adCount: 5,
                  showProgressBar: true,
                  progressBarColor: Colors.white,
                  settings: AquaSettings(
                    adRefreshSeconds: 5,
                    hideIfEmpty: true,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 528,
                  height: 528 / (16 / 9),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Center(
                    child: Text('Box Sotto', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
