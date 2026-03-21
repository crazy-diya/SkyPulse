import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  String _tempUnit = 'Celsius';
  String _windUnit = 'm/s';
  bool _notifications = true;
  bool _autoRefresh = true;
  bool _darkMode = true;
  String _refreshInterval = '30 min';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile card
                      _buildProfileCard(),
                      const SizedBox(height: 24),
                      _buildSection('Units', [
                        _buildDropdownTile(
                          Icons.thermostat_rounded,
                          'Temperature Unit',
                          _tempUnit,
                          ['Celsius', 'Fahrenheit', 'Kelvin'],
                          Colors.red,
                          (v) => setState(() => _tempUnit = v),
                        ),
                        _buildDropdownTile(
                          Icons.air_rounded,
                          'Wind Speed',
                          _windUnit,
                          ['m/s', 'km/h', 'mph', 'knots'],
                          Colors.teal,
                          (v) => setState(() => _windUnit = v),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Preferences', [
                        _buildSwitchTile(
                            Icons.notifications_rounded,
                            'Weather Alerts',
                            'Get notified about severe weather',
                            _notifications,
                            Colors.orange,
                            (v) => setState(() => _notifications = v)),
                        _buildSwitchTile(
                            Icons.refresh_rounded,
                            'Auto Refresh',
                            'Update weather automatically',
                            _autoRefresh,
                            Colors.blue,
                            (v) => setState(() => _autoRefresh = v)),
                        _buildSwitchTile(
                            Icons.dark_mode_rounded,
                            'Dark Mode',
                            'Enable dark theme',
                            _darkMode,
                            Colors.indigo,
                            (v) => setState(() => _darkMode = v)),
                        _buildDropdownTile(
                          Icons.timer_rounded,
                          'Refresh Interval',
                          _refreshInterval,
                          ['15 min', '30 min', '1 hour', '3 hours'],
                          Colors.purple,
                          (v) => setState(() => _refreshInterval = v),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('About', [
                        _buildInfoTile(Icons.info_rounded, 'Version', '2.0.0', Colors.blueGrey),
                        _buildInfoTile(Icons.cloud_rounded, 'Data Provider', 'OpenWeatherMap', Colors.blue),
                        _buildInfoTile(Icons.update_rounded, 'Last Updated', 'Just now', Colors.green),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Developer', [
                        _buildActionTile(Icons.bug_report_rounded, 'Report a Bug', Colors.red,
                            () => _showSnack(context, 'Bug report sent')),
                        _buildActionTile(Icons.star_rounded, 'Rate the App', Colors.yellow,
                            () => _showSnack(context, 'Thank you!')),
                        _buildActionTile(Icons.privacy_tip_rounded, 'Privacy Policy', Colors.blueGrey,
                            () => _showSnack(context, 'Opening privacy policy...')),
                      ]),
                      const SizedBox(height: 40),
                      // Version badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B3A5C),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wb_sunny_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 8),
                            Text('SkyPulse v2.0.0',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SkyPulse',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Weather & Climate Intelligence',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Pro',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1B3A5C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: children.asMap().entries.map((e) {
              return Column(
                children: [
                  e.value,
                  if (e.key < children.length - 1)
                    Divider(
                        color: Colors.white.withValues(alpha: 0.06),
                        height: 1,
                        indent: 16,
                        endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile(IconData icon, String title, String value,
      List<String> options, Color color, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF1B3A5C),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              icon: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 18),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle,
      bool value, Color color, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
            activeTrackColor: color.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
      IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
                child: Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14))),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1B3A5C),
      behavior: SnackBarBehavior.floating,
    ));
  }
}
