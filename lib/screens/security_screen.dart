import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dashboard.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _myBox = Hive.box('transactions_box');
  
  String _inputPin = "";
  String _savedPin = "";
  String _firstEnteredPin = ""; 
  
  bool _isSettingUp = false; 
  bool _isConfirming = false;
  String _message = "Enter security PIN to unlock";

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  void _checkPinStatus() {
    final dynamic masterPin = _myBox.get("APP_MASTER_PIN");
    if (masterPin == null || masterPin.toString().trim().isEmpty) {
      setState(() {
        _isSettingUp = true;
        _message = "Create your 4-Digit Security PIN";
      });
    } else {
      _savedPin = masterPin.toString();
    }
  }

  void _handleKeyPress(String value) {
    if (_inputPin.length >= 4) return;

    setState(() {
      _inputPin += value;
    });

    if (_inputPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), () => _evaluatePinPipeline());
    }
  }

  void _handleBackspace() {
    if (_inputPin.isEmpty) return;
    setState(() {
      _inputPin = _inputPin.substring(0, _inputPin.length - 1);
    });
  }

  void _evaluatePinPipeline() {
    if (_isSettingUp) {
      if (!_isConfirming) {
        _firstEnteredPin = _inputPin;
        setState(() {
          _inputPin = "";
          _isConfirming = true;
          _message = "Re-enter your PIN to confirm";
        });
      } else {
        if (_inputPin == _firstEnteredPin) {
          _myBox.put("APP_MASTER_PIN", _inputPin);
          _handleSuccessNavigation();
        } else {
          _triggerFailureFeedback("PINs do not match. Restarting.");
          setState(() {
            _firstEnteredPin = "";
            _isConfirming = false;
            _message = "Create your 4-Digit Security PIN";
          });
        }
      }
    } else {
      if (_inputPin == _savedPin) {
        _handleSuccessNavigation();
      } else {
        _triggerFailureFeedback("Incorrect PIN. Try again.");
      }
    }
  }

  void _triggerFailureFeedback(String msg) {
    setState(() {
      _inputPin = "";
      _message = msg;
    });
  }

  void _handleSuccessNavigation() {
    if (!mounted) return;
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true); 
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFF1e3c72),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isSettingUp ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isSettingUp ? "Secure Configuration" : "Welcome Back",
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _message,
                key: ValueKey<String>(_message),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
              ),
            ),
            
            const Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool isFilled = index < _inputPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: isFilled ? Colors.white : Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: isFilled ? [
                      BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)
                    ] : [],
                  ),
                );
              }),
            ),
            
            const Spacer(flex: 2),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKeypadButton("1"), _buildKeypadButton("2"), _buildKeypadButton("3")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKeypadButton("4"), _buildKeypadButton("5"), _buildKeypadButton("6")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildKeypadButton("7"), _buildKeypadButton("8"), _buildKeypadButton("9")],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCancelButton(),
                      _buildKeypadButton("0"),
                      _buildBackspaceButton(),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String value) {
    return GestureDetector(
      onTap: () => _handleKeyPress(value),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return GestureDetector(
      onTap: _handleBackspace,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: const Center(
          child: Icon(Icons.backspace_outlined, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    if (!Navigator.canPop(context)) return const SizedBox(width: 72, height: 72);
    
    return GestureDetector(
      onTap: () => Navigator.pop(context, false),
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: const Center(
          child: Icon(Icons.close_rounded, color: Colors.white54, size: 24),
        ),
      ),
    );
  }
}