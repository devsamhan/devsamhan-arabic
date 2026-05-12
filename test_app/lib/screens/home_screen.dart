import 'package:flutter/material.dart';
import 'teacher_search_screen.dart';
import 'student_register_screen.dart';
import 'numbers_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختبار المكتبات العربية'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Text(
              'اختر الشاشة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _NavButton(
              label: 'شاشة البحث عن مدرس',
              subtitle: 'arabic_text · ArabicSearchField',
              icon: Icons.search,
              color: Colors.blue,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TeacherSearchScreen())),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'شاشة تسجيل طالب',
              subtitle: 'flutter_arabic_ui · ArabicValidators',
              icon: Icons.person_add,
              color: Colors.green,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StudentRegisterScreen())),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'شاشة الأرقام والفواتير',
              subtitle: 'ArabicNumberField · normalizeDigits',
              icon: Icons.calculate,
              color: Colors.orange,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NumbersScreen())),
            ),
            const SizedBox(height: 16),
            _NavButton(
              label: 'شاشة اختبار الطرفية',
              subtitle: 'arabic_bidi · prepareForTerminal',
              icon: Icons.terminal,
              color: Colors.purple,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TerminalScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _NavButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
