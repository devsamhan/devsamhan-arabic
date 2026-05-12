import 'package:flutter/material.dart';
import 'package:arabic_text/arabic_text.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class NumbersScreen extends StatefulWidget {
  const NumbersScreen({super.key});

  @override
  State<NumbersScreen> createState() => _NumbersScreenState();
}

class _NumbersScreenState extends State<NumbersScreen> {
  String _liveVisible = '';
  String _liveNormalized = '';

  static const _conversions = [
    ('١٢٣٤٥', 'western'),
    ('67890', 'eastern'),
    ('۱۲۳', 'western'), // Persian → Western
    ('1,250.00', 'eastern'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأرقام والفواتير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('تحويلات ثابتة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                },
                border: TableBorder.all(
                    color: Colors.grey[300]!, borderRadius: BorderRadius.circular(4)),
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[100]),
                    children: const [
                      _Cell('المدخل', bold: true),
                      _Cell('الاتجاه', bold: true),
                      _Cell('الناتج', bold: true),
                    ],
                  ),
                  for (final (input, dir) in _conversions)
                    TableRow(children: [
                      _Cell(input),
                      _Cell(dir == 'western' ? '← غربي' : '← شرقي'),
                      _Cell(ArabicText.normalizeDigits(input, to: dir)),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('إدخال حي',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'اكتب أرقاماً (غربية أو شرقية أو فارسية) — '
            'الحقل يحوّلها إلى شرقية، والمعيار يُرجعها غربية دائماً.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ArabicNumberField(
            digitDirection: ArabicDigitDirection.eastern,
            decoration: const InputDecoration(
              labelText: 'أدخل رقماً',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            onChanged: (v) => setState(() => _liveVisible = v),
            onNormalizedChanged: (v) => setState(() => _liveNormalized = v),
          ),
          const SizedBox(height: 12),
          if (_liveVisible.isNotEmpty)
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LabelValue('مرئي (شرقي)', _liveVisible),
                    _LabelValue('معياري (غربي)', _liveNormalized),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          const Text('ملاحظة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'تُحوّل normalizeDigits الأرقامَ فقط (٠–٩ وما يقابلها).\n'
            'الفواصل والنقاط (,.) تبقى كما هي — '
            'الفاصلة العربية ٬ (U+066C) والفاصلة العشرية ٫ (U+066B) '
            'تستوجب معالجة إضافية خارج نطاق المكتبة.',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool bold;
  const _Cell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'monospace',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  const _LabelValue(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        ],
      ),
    );
  }
}
