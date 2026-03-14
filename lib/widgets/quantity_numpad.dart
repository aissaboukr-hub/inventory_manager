import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class QuantityNumpad extends StatefulWidget {
  final String productName;
  final String? productCode;
  final double initialValue;

  const QuantityNumpad({
    super.key,
    required this.productName,
    this.productCode,
    this.initialValue = 0,
  });

  @override
  State<QuantityNumpad> createState() => _QuantityNumpadState();
}

class _QuantityNumpadState extends State<QuantityNumpad> {
  String _display = '';
  bool _isNegative = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != 0) {
      _isNegative = widget.initialValue < 0;
      _display = widget.initialValue.abs().toStringAsFixed(
            widget.initialValue.truncateToDouble() == widget.initialValue
                ? 0
                : 2,
          );
    }
  }

  double get _value {
    final v = double.tryParse(_display) ?? 0;
    return _isNegative ? -v : v;
  }

  void _press(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      switch (key) {
        case 'C':
          _display = '';
          _isNegative = false;
          break;
        case '⌫':
          if (_display.isNotEmpty) {
            _display = _display.substring(0, _display.length - 1);
          }
          break;
        case '+/-':
          _isNegative = !_isNegative;
          break;
        case '.':
          if (!_display.contains('.')) {
            _display = _display.isEmpty ? '0.' : '$_display.';
          }
          break;
        default:
          // Max 8 chiffres
          if (_display.replaceAll('.', '').replaceAll('-', '').length < 8) {
            _display += key;
          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _display.isEmpty
        ? '0'
        : '${_isNegative ? '-' : ''}$_display';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Produit
          Text(
            widget.productName,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.productCode != null)
            Text(
              widget.productCode!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          const SizedBox(height: 16),

          // Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              displayText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: _isNegative ? AppTheme.error : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pavé numérique
          ..._buildRows(),
          const SizedBox(height: 8),

          // Valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _display.isEmpty
                  ? null
                  : () => Navigator.pop(context, _value),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Valider'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  List<Widget> _buildRows() {
    const layout = [
      ['7', '8', '9', '⌫'],
      ['4', '5', '6', 'C'],
      ['1', '2', '3', '+/-'],
      ['.', '0', '00', ''],
    ];

    return layout.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: row.map((key) {
            if (key.isEmpty) return const Expanded(child: SizedBox());
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _NumKey(label: key, onTap: () => _press(key)),
              ),
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAction = ['⌫', 'C', '+/-', '.', '00'].contains(label);
    return Material(
      color: isAction ? Colors.grey.shade100 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          child: label == '⌫'
              ? const Icon(Icons.backspace_outlined, size: 20)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight:
                        isAction ? FontWeight.w400 : FontWeight.w600,
                    color: label == 'C'
                        ? AppTheme.error
                        : label == '+/-'
                            ? AppTheme.warning
                            : Colors.black87,
                  ),
                ),
        ),
      ),
    );
  }
}
