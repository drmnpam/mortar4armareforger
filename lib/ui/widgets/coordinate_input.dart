import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_theme.dart';

/// Coordinate input field with military styling
class CoordinateInput extends StatefulWidget {
  final String label;
  final double value;
  final Function(double) onChanged;
  final String? suffix;
  final String? hintText;
  final bool readOnly;

  const CoordinateInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix,
    this.hintText,
    this.readOnly = false,
  });

  @override
  State<CoordinateInput> createState() => _CoordinateInputState();
}

class _CoordinateInputState extends State<CoordinateInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant CoordinateInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_focusNode.hasFocus) {
      return;
    }

    final next = _formatValue(widget.value);
    if (_controller.text != next) {
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
  }

  String _formatValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: widget.readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFamily: 'monospace',
            color: AppTheme.textPrimary,
          ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        suffixText: widget.suffix,
        suffixStyle: TextStyle(color: AppTheme.textMuted),
      ),
      onChanged: (value) {
        final parsed = double.tryParse(value) ?? 0;
        widget.onChanged(parsed);
      },
    );
  }
}

/// Grid reference input (e.g., "0123 0456")
class GridReferenceInput extends StatelessWidget {
  final String label;
  final String? value;
  final Function(String) onChanged;

  const GridReferenceInput({
    super.key,
    required this.label,
    this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: TextInputType.number,
      maxLength: 9, // "0123 0456"
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontFamily: 'monospace',
        letterSpacing: 2,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        hintText: '0123 0456',
        hintStyle: TextStyle(
          color: AppTheme.textMuted,
          letterSpacing: 2,
        ),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _GridReferenceFormatter(),
      ],
      onChanged: onChanged,
    );
  }
}

class _GridReferenceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    
    if (text.length <= 4) {
      return newValue.copyWith(text: text);
    }
    
    // Insert space after 4 digits
    final first = text.substring(0, 4);
    final second = text.substring(4);
    final formatted = '$first $second';
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Large numeric display for firing solutions
class SolutionValueDisplay extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final double fontSize;

  const SolutionValueDisplay({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.fontSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            color: color ?? AppTheme.accent,
          ),
        ),
      ],
    );
  }
}

/// Action button with military styling
class MilitaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDanger;

  const MilitaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    
    if (isDanger) {
      backgroundColor = AppTheme.danger;
      foregroundColor = Colors.white;
    } else if (isPrimary) {
      backgroundColor = AppTheme.primary;
      foregroundColor = Colors.black;
    } else {
      backgroundColor = AppTheme.surfaceLight;
      foregroundColor = AppTheme.textPrimary;
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Info row with label and value
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight ? AppTheme.accent : AppTheme.textPrimary,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

/// Card with tactical styling
class TacticalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  const TacticalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? AppTheme.gridLine,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

/// Copy to clipboard button
class CopyButton extends StatelessWidget {
  final String text;
  final String? successMessage;

  const CopyButton({
    super.key,
    required this.text,
    this.successMessage,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage ?? 'Copied to clipboard'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      icon: const Icon(Icons.copy, size: 20),
      tooltip: 'Copy',
      color: AppTheme.accent,
    );
  }
}
