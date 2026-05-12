import 'package:flutter/material.dart';
import 'package:arabic_bidi/arabic_bidi.dart';

const _lines = [
  'محمد',
  'السلام عليكم',
  'مُحَمَّد',
  'مـحـمـد',
  'Error في الملف',
  'تم حفظ file.txt',
  'الطلب رقم 123',
  'رقم ١٢٣ هاتف',
  'invoice ١٢٣ تم الحفظ',
];

class TerminalScreen extends StatelessWidget {
  const TerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختبار الطرفية')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '# محاكاة مخرجات الطرفية\n'
              '# arabic_bidi.prepareForTerminal + detectDirection',
              style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'monospace',
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          for (final line in _lines) _TerminalLineCard(line),
        ],
      ),
    );
  }
}

class _TerminalLineCard extends StatelessWidget {
  final String original;
  const _TerminalLineCard(this.original);

  @override
  Widget build(BuildContext context) {
    final prepared = ArabicBidi.prepareForTerminal(original);
    final dir = ArabicBidi.detectDirection(original);

    final dirLabel = switch (dir) {
      Direction.rtl => 'RTL',
      Direction.ltr => 'LTR',
      Direction.mixed => 'MIXED',
    };
    final dirColor = switch (dir) {
      Direction.rtl => Colors.blue[700]!,
      Direction.ltr => Colors.orange[700]!,
      Direction.mixed => Colors.purple[700]!,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dirColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(dirLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            _TermRow('المدخل', original),
            const SizedBox(height: 4),
            _TermRow('الطرفية', prepared),
          ],
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  final String label;
  final String value;
  const _TermRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label:',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
      ],
    );
  }
}
