import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/app_state_manager.dart'; // Import your global state manager

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _myBox = Hive.box('transactions_box');

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
              // Preserve settings configurations across wipes
              final savedCurrency = _myBox.get('global_currency', defaultValue: '\$');
              final savedDark = _myBox.get('is_dark_mode', defaultValue: false);
              final savedBiometrics = _myBox.get('is_biometric_enabled', defaultValue: true);
              
              await _myBox.clear();
              
              // Restore preference contexts post clear actions
              _myBox.put('global_currency', savedCurrency);
              _myBox.put('is_dark_mode', savedDark);
              _myBox.put('is_biometric_enabled', savedBiometrics);

              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context, true); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All transaction records have been wiped")),
              );
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showEditLimitDialog(String title, double currentLimit) {
    final controller = TextEditingController(text: currentLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Set $title Limit"),
        content: ValueListenableBuilder<String>(
          valueListenable: AppStateManager.currencyNotifier,
          builder: (context, currencySymbol, child) {
            return TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                prefixText: "$currencySymbol ",
                hintText: "Enter amount",
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit >= 0) {
                setState(() {
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

  void _showCurrencyPicker(BuildContext context, String currentCurrency) {
    final currencies = ['\$', '€', '£', '¥', '₨', 'د.إ'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Display Currency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final cur = currencies[index];
                    return ListTile(
                      title: Text(cur, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      trailing: cur == currentCurrency ? const Icon(Icons.check_circle, color: Colors.teal) : null,
                      onTap: () {
                        AppStateManager.updateCurrency(cur);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Security", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          
          // Fixed: Biometric Authentication Switch connected to Global State Manager
          ValueListenableBuilder<bool>(
            valueListenable: AppStateManager.biometricNotifier,
            builder: (context, isBiometricEnabled, child) {
              return SwitchListTile(
                secondary: const Icon(Icons.face_unlock_rounded, color: Colors.blue),
                title: const Text("Biometric Authentication"),
                subtitle: const Text("Face ID verification for access"),
                value: isBiometricEnabled,
                onChanged: (val) => AppStateManager.toggleBiometrics(val),
              );
            },
          ),
          
          const Divider(),
          const SizedBox(height: 10),
          const Text("Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),

          // 1. Dynamic Mode Toggle Switch
          ValueListenableBuilder<ThemeMode>(
            valueListenable: AppStateManager.themeModeNotifier,
            builder: (context, currentMode, child) {
              final isDark = currentMode == ThemeMode.dark;
              return SwitchListTile(
                secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: Colors.purple),
                title: const Text("AMOLED Dark Mode"),
                subtitle: const Text("Deep blacks for efficient battery use"),
                value: isDark,
                onChanged: (val) => AppStateManager.toggleTheme(val),
              );
            },
          ),

          // 2. Global Currency Customizer Tile
          ValueListenableBuilder<String>(
            valueListenable: AppStateManager.currencyNotifier,
            builder: (context, currentCurrency, child) {
              return ListTile(
                leading: const Icon(Icons.monetization_on_outlined, color: Colors.teal),
                title: const Text("Primary Currency"),
                subtitle: Text("Currently rendering in ($currentCurrency)"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCurrencyPicker(context, currentCurrency),
              );
            },
          ),

          const Divider(),
          const SizedBox(height: 10),
          const Text("Budget Limits", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          
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
      trailing: ValueListenableBuilder<String>(
        valueListenable: AppStateManager.currencyNotifier,
        builder: (context, currencySymbol, child) {
          return Text(
            "$currencySymbol${currentLimit.toStringAsFixed(0)}", 
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1e3c72))
          );
        },
      ),
      onTap: () => _showEditLimitDialog(title, currentLimit),
    );
  }
}