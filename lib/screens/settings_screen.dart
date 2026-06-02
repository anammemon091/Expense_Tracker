import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/app_state_manager.dart';
import 'manage_categories_screen.dart'; 
import 'security_screen.dart'; // Import to handle routing setups if needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _myBox = Hive.box('transactions_box');

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text("This will wipe your history, configurations, and security credentials."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              // Preserve settings configurations before completely purging the storage layer
              final savedCurrency = _myBox.get('global_currency', defaultValue: '\$');
              final savedDark = _myBox.get('is_dark_mode', defaultValue: false);
              
              await _myBox.clear();
              
              // Restore foundational preference variables
              await _myBox.put('global_currency', savedCurrency);
              await _myBox.put('is_dark_mode', savedDark);

              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              
              if (!mounted) return;
              Navigator.pop(context, true); 
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All cache stores and tracking matrices have been purged")),
              );
            }, 
            child: const Text("Clear", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _togglePinLock(bool activate) async {
    if (activate) {
      // Direct user to configure their security credentials layout
       await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SecurityScreen()),
      );
      // Force UI refresh state loop upon return
      setState(() {});
    } else {
      // Wipe the master tracking PIN to completely deactivate secure gating checkpoints
      await _myBox.delete("APP_MASTER_PIN");
      setState(() {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PIN Lock security has been deactivated")),
      );
    }
  }

  void _showCurrencyPicker(BuildContext context, String currentCurrency) {
    final currencies = ['\$', '€', '£', '¥', '₨', 'د.إ'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Display Currency", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
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
    // Determine live device secure locking profile status
    final dynamic activePin = _myBox.get("APP_MASTER_PIN");
    final bool isPinSetupActive = activePin != null && activePin.toString().trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("Security", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),
          
          // 🔒 Custom Keypad PIN Authentication Switch Control
          SwitchListTile(
            secondary: Icon(
              isPinSetupActive ? Icons.lock_rounded : Icons.lock_open_rounded, 
              color: isPinSetupActive ? Colors.green : Colors.blueGrey
            ),
            title: const Text("App PIN Lock Security"),
            subtitle: Text(
              isPinSetupActive 
                  ? "Enabled (Secure Keypad Gate Active)" 
                  : "Disabled (Bypass Mode Active)"
            ),
            value: isPinSetupActive,
            onChanged: (val) => _togglePinLock(val),
          ),
          
          const Divider(height: 32),
          const Text("Preferences", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),

          // AMOLED Dark Mode Toggle Switch
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

          // Global Currency Customizer Tile
          ValueListenableBuilder<String>(
            valueListenable: AppStateManager.currencyNotifier,
            builder: (context, currentCurrency, child) {
              return ListTile(
                leading: const Icon(Icons.monetization_on_outlined, color: Colors.teal),
                title: const Text("Primary Currency"),
                subtitle: Text("Currently rendering in ($currentCurrency)"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => _showCurrencyPicker(context, currentCurrency),
              );
            },
          ),

          const Divider(height: 32),
          const Text("Structure", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 10),

          // Manage Categories Entry Point Terminal
          ListTile(
            leading: const Icon(Icons.category_outlined, color: Color(0xFF1e3c72)),
            title: const Text("Manage Categories"),
            subtitle: const Text("Customize transaction tags and budget limits"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
              );
            },
          ),
          
          const Divider(height: 32),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            title: const Text("Reset App Data", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: _clearData,
          ),
        ],
      ),
    );
  }
}