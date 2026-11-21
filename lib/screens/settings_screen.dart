import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  String distanceUnit = 'Kilometers (KM)';
  String preferredFuel = 'Gasoline';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Adjust the app theme'),
            value: isDarkMode,
            onChanged: (val) => setState(() => isDarkMode = val),
          ),
          const Divider(),
          _SectionHeader(title: 'Preferences'),
          ListTile(
            title: const Text('Distance Unit'),
            subtitle: Text(distanceUnit),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUnitPicker(),
          ),
          ListTile(
            title: const Text('Preferred Fuel Type'),
            subtitle: Text(preferredFuel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFuelPicker(),
          ),
          const Divider(),
          _SectionHeader(title: 'About'),
          const ListTile(
            title: Text('App Version'),
            trailing: Text('1.0.0'),
          ),
          const ListTile(
            title: Text('Data Source'),
            trailing: Text('Mock Service'),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Kilometers (KM)'),
              onTap: () {
                setState(() => distanceUnit = 'Kilometers (KM)');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Miles (MI)'),
              onTap: () {
                setState(() => distanceUnit = 'Miles (MI)');
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showFuelPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Gasoline',
            'Diesel',
            'LPG'
          ].map((fuel) {
            return ListTile(
              title: Text(fuel),
              onTap: () {
                setState(() => preferredFuel = fuel);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
