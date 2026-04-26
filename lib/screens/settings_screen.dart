import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _myBox = Hive.box('transactions_box');
  bool _isFaceIDEnabled = true;

  // Load saved limits from Hive or use defaults if they don't exist
  double get _housingLimit => _myBox.get('limit_Housing', defaultValue: 1500.0);
  double get _transportLimit => _myBox.get('limit_Transport', defaultValue: 500.0);
  double get _foodLimit => _myBox.get('limit_Food', defaultValue: 800.0);

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text("This will wipe your history and reset your balance."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              await _myBox.clear();
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context, true); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All data has been wiped")),
              );
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  // New: Function to show the editing popup
  void _showEditLimitDialog(String title, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set $title Limit"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: "\$ ",
            hintText: "Enter amount",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit >= 0) {
                setState(() {
                  // Save directly to Hive using the category name as part of the key
                  _myBox.put('limit_$title', newLimit);
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Security", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          SwitchListTile(
            secondary: const Icon(Icons.face_unlock_rounded, color: Colors.blue),
            title: const Text("Biometric Authentication"),
            subtitle: const Text("Face ID verification for access"),
            value: _isFaceIDEnabled,
            onChanged: (val) => setState(() => _isFaceIDEnabled = val),
          ),
          const Divider(),
          const SizedBox(height: 10),
          const Text("Budget Limits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          
          // Pass the category name and current value to the builder
          _buildLimitTile("Housing", _housingLimit),
          _buildLimitTile("Transport", _transportLimit),
          _buildLimitTile("Food", _foodLimit),
          
          const Divider(),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Reset App Data", style: TextStyle(color: Colors.red)),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }

  Widget _buildLimitTile(String title, double currentLimit) {
    return ListTile(
      title: Text(title),
      leading: const Icon(Icons.edit_note, color: Colors.grey),
      trailing: Text(
        "\$${currentLimit.toStringAsFixed(0)}", 
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1e3c72))
      ),
      onTap: () => _showEditLimitDialog(title, currentLimit),
    );
  }
}