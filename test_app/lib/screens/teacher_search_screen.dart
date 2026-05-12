import 'package:flutter/material.dart';
import 'package:arabic_text/arabic_text.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

const _teachers = [
  'مُحَمَّد أحمد',
  'فَاطِمَةُ العلي',
  'إبراهيم السالم',
  'آدم الخالد',
  'موسى العمري',
  'علی المطيري',
  'عبدالرَّحمن القحطاني',
  'نُورَة الشمري',
  'خَالِد الدوسري',
  'مَرْيَم الغامدي',
];

class TeacherSearchScreen extends StatefulWidget {
  const TeacherSearchScreen({super.key});

  @override
  State<TeacherSearchScreen> createState() => _TeacherSearchScreenState();
}

class _TeacherSearchScreenState extends State<TeacherSearchScreen> {
  String _rawText = '';
  String _searchKey = '';
  String _looseKey = '';
  List<String> _filtered = _teachers;

  void _handleChanged(String raw) {
    final queryKey = ArabicText.toLooseSearchKey(raw);
    setState(() {
      _rawText = raw;
      _searchKey = ArabicText.toSearchKey(raw);
      _looseKey = queryKey;
      _filtered = raw.isEmpty
          ? _teachers
          : _teachers
              .where((name) =>
                  ArabicText.toLooseSearchKey(name).contains(queryKey))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('البحث عن مدرس')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ArabicSearchField(
              onChanged: _handleChanged,
              decoration: const InputDecoration(
                labelText: 'ابحث عن مدرس',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow('النص الخام', _rawText.isEmpty ? '—' : _rawText),
                    _InfoRow('مفتاح البحث العادي',
                        _searchKey.isEmpty ? '—' : _searchKey),
                    _InfoRow('مفتاح البحث المتساهل',
                        _looseKey.isEmpty ? '—' : _looseKey),
                    _InfoRow('عدد النتائج', '${_filtered.length}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('لا توجد نتائج'))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final name = _filtered[i];
                        return ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.person)),
                          title: Text(name),
                          subtitle: Text(
                            'عادي: ${ArabicText.toSearchKey(name)}  |  '
                            'متساهل: ${ArabicText.toLooseSearchKey(name)}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
