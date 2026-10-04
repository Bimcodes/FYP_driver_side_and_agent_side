import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class PinInputWidget extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String) onChanged;
  final bool hasError;

  const PinInputWidget({
    super.key,
    this.length = 4,
    required this.onCompleted,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (index) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    String currentPin = _controllers.map((c) => c.text).join();
    widget.onChanged(currentPin);
    
    if (currentPin.length == widget.length) {
      widget.onCompleted(currentPin);
      FocusScope.of(context).unfocus();
    }
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _controllers[index - 1].text = '';
        _focusNodes[index - 1].requestFocus();
        String currentPin = _controllers.map((c) => c.text).join();
        widget.onChanged(currentPin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: 56,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) => _onKeyEvent(event, index),
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  obscureText: _obscureText,
                  maxLength: 1,
                  style: TextStyle(
                    color: widget.hasError ? AppColors.error : AppColors.agentTextDark,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: widget.hasError ? AppColors.error : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: widget.hasError ? AppColors.error : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: widget.hasError ? AppColors.error : AppColors.authPrimary, width: 2),
                    ),
                  ),
                  onChanged: (value) => _onChanged(value, index),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
