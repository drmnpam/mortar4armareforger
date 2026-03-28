import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_theme.dart';

/// Fast grid coordinate input with 6-digit and 8-digit support
/// Format: XXX YYY (6-digit) or XXXX YYYY (8-digit)
class GridCoordinateInput extends StatefulWidget {
  final String? label;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int digits; // 6 or 8
  final String? initialValue;
  final bool autofocus;
  final FocusNode? focusNode;
  
  const GridCoordinateInput({
    super.key,
    this.label,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.digits = 6,
    this.initialValue,
    this.autofocus = false,
    this.focusNode,
  });

  @override
  State<GridCoordinateInput> createState() => _GridCoordinateInputState();
}

class _GridCoordinateInputState extends State<GridCoordinateInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isValid = true;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
  }
  
  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final halfDigits = widget.digits ~/ 2;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isValid ? AppTheme.gridLine : AppTheme.danger,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // X coordinate input
              Expanded(
                child: _DigitInput(
                  controller: _controller,
                  digits: halfDigits,
                  hint: 'X' * halfDigits,
                  onChanged: _onChanged,
                  autofocus: widget.autofocus,
                ),
              ),
              
              // Separator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '−',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Y coordinate input
              Expanded(
                child: _DigitInput(
                  controller: _controller,
                  digits: halfDigits,
                  hint: 'Y' * halfDigits,
                  onChanged: _onChanged,
                  isY: true,
                ),
              ),
            ],
          ),
        ),
        
        // Quick entry buttons
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(
                'QUICK:',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              _QuickButton(
                label: '6-digit',
                isActive: widget.digits == 6,
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _QuickButton(
                label: '8-digit',
                isActive: widget.digits == 8,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _onChanged(String value) {
    // Validate format
    final clean = value.replaceAll(RegExp(r'[^\d]'), '');
    final isValid = clean.length == widget.digits || clean.isEmpty;
    
    setState(() => _isValid = isValid);
    
    if (isValid) {
      widget.onChanged?.call(value);
    }
  }
}

class _DigitInput extends StatelessWidget {
  final TextEditingController controller;
  final int digits;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool autofocus;
  final bool isY;
  
  const _DigitInput({
    required this.controller,
    required this.digits,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.isY = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: isY ? null : controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: digits,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        color: AppTheme.accent,
        letterSpacing: 4,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 24,
          color: AppTheme.textMuted.withOpacity(0.3),
          letterSpacing: 4,
        ),
        border: InputBorder.none,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(digits),
      ],
      onChanged: onChanged,
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  
  const _QuickButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.gridLine,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primary : AppTheme.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// Simple 6-digit grid input for quick entry
class QuickGridInput extends StatelessWidget {
  final String label;
  final ValueChanged<String> onComplete;
  final VoidCallback? onCancel;
  
  const QuickGridInput({
    super.key,
    required this.label,
    required this.onComplete,
    this.onCancel,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Text(
        label,
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GridCoordinateInput(
            digits: 6,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter 6-digit grid reference\nFormat: XXX YYY',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }
}
