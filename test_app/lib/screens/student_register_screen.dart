import 'package:flutter/material.dart';
import 'package:arabic_text/arabic_text.dart';
import 'package:flutter_arabic_ui/flutter_arabic_ui.dart';

class StudentRegisterScreen extends StatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  State<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends State<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  Map<String, String>? _summary;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      setState(() {
        _summary = {
          'name': name,
          'searchKey': ArabicText.toSearchKey(name),
          'slug': ArabicText.toSlug(name),
          'normalizedName': ArabicText.normalizeName(name),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل طالب')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Field 1: name — requiredArabic
              TextFormField(
                controller: _nameController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                inputFormatters: const [ArabicInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'اسم الطالب',
                  border: OutlineInputBorder(),
                ),
                validator: ArabicValidators.requiredArabic,
              ),
              const SizedBox(height: 16),

              // Field 2: phone — ArabicNumberField (western digits)
              const Text('رقم الهاتف',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              ArabicNumberField(
                controller: _phoneController,
                digitDirection: ArabicDigitDirection.western,
                decoration: const InputDecoration(
                  hintText: '٠٥٠١٢٣٤٥٦٧',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Field 3: city — arabicOnly
              TextFormField(
                controller: _cityController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  border: OutlineInputBorder(),
                ),
                validator: ArabicValidators.arabicOnly,
              ),
              const SizedBox(height: 16),

              // Field 4: notes — minArabicLetters(3)
              TextFormField(
                controller: _notesController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  border: OutlineInputBorder(),
                  helperText: 'ثلاثة أحرف عربية على الأقل',
                ),
                validator: ArabicValidators.minArabicLetters(3),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('تسجيل'),
              ),

              if (_summary != null) ...[
                const SizedBox(height: 24),
                const Divider(),
                const Text('ملخص التسجيل',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryRow('الاسم الأصلي', _summary!['name']!),
                        _SummaryRow('مفتاح البحث', _summary!['searchKey']!),
                        _SummaryRow('المعرف (slug)', _summary!['slug']!),
                        _SummaryRow('الاسم المعياري', _summary!['normalizedName']!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
