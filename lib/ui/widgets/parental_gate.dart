import 'package:flutter/material.dart';

/// Simple parental gate: an adult must answer a multiplication question.
/// Used before settings (rule H). No purchase inside the app (paid app).
Future<bool> showParentalGate(BuildContext context) async {
  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => const _GateDialog(),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog();

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  static const List<int> _answers = <int>[24, 36, 42];
  int _picked = -1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('🛡️ Grown-ups only', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Please answer to continue:\nWhat is 6 × 7?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _answers.map((int a) {
              final bool selected = _picked == a;
              return GestureDetector(
                onTap: () {
                  setState(() => _picked = a);
                  if (a == 42) {
                    Navigator.of(context).pop(true);
                  } else if (!selected) {
                    // gentle wrong pick: just mark selection
                  }
                },
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: selected && a != 42
                        ? Colors.red.shade50
                        : const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected && a != 42
                          ? Colors.red.shade200
                          : const Color(0xFFDDD6FE),
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$a',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_picked != -1 && _picked != 42)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Try again 🙂', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Back', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }
}
