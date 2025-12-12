import 'package:flutter/material.dart';
import 'package:aqua_ad_widget/aqua_ad_widget.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  int _buildCount = 0;
  int _loadAdCallCount = 0;
  bool _showWidget = true;
  bool _changeLocale = false;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Loop Test'),
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          // Debug Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Build Count: $_buildCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Load Ad Calls: $_loadAdCallCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => setState(() => _showWidget = !_showWidget),
                      child: Text(_showWidget ? 'Hide Widget' : 'Show Widget'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => setState(() => _changeLocale = !_changeLocale),
                      child: Text('Toggle Locale: ${_changeLocale ? 'IT' : 'EN'}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Test Widget
          Expanded(
            child: Container(
              color: Colors.blue[50],
              child: Center(
                child: _showWidget
                    ? DebugAquaAdWidget(
                        zoneId: 2,
                        width: 300,
                        ratio: 16 / 9,
                        borderRadius: 12,
                        adCount: 'auto',
                        onLoadAdCalled: () {
                          setState(() => _loadAdCallCount++);
                        },
                        settings: AquaSettings(
                          hideIfEmpty: true,
                          locale: _changeLocale ? 'it' : 'en',
                        ),
                      )
                    : const Text('Widget Hidden'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget wrapper per monitorare le chiamate
class DebugAquaAdWidget extends StatelessWidget {
  final int zoneId;
  final double? width;
  final double ratio;
  final double? borderRadius;
  final dynamic adCount;
  final AquaSettings? settings;
  final VoidCallback? onLoadAdCalled;

  const DebugAquaAdWidget({
    super.key,
    required this.zoneId,
    this.width,
    this.ratio = 16/9,
    this.borderRadius,
    this.adCount = 1,
    this.settings,
    this.onLoadAdCalled,
  });

  @override
  Widget build(BuildContext context) {
    // Monitora quando il widget viene ricostruito
    print('DebugAquaAdWidget build() called');
    
    return AquaAdWidget(
      zoneId: zoneId,
      width: width,
      ratio: ratio,
      borderRadius: borderRadius,
      adCount: adCount,
      settings: settings,
    );
  }
}