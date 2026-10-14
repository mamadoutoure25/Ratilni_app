import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false, // Hidden back button for tab
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildSectionTitle('Paramètres'),
          _buildSettingsTile(
            icon: LucideIcons.globe,
            title: 'Langue',
            subtitle: provider.languages.firstWhere(
              (l) => l.locale == provider.currentLocale,
              orElse: () => provider.languages.isNotEmpty ? provider.languages.first : provider.languages.first, // Fallback
            ).native,
            onTap: () {
              _showLanguageDialog(context, provider);
            },
          ),
          _buildSettingsTile(
            icon: LucideIcons.bell,
            title: 'Notifications',
            subtitle: 'Gérer les alertes',
            onTap: () {},
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('À propos'),
          _buildSettingsTile(
            icon: LucideIcons.info,
            title: 'À propos de Qira',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: LucideIcons.shield,
            title: 'Politique de confidentialité',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: LucideIcons.star,
            title: 'Évaluer l\'application',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.goldAccent,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: AppTheme.goldAccent),
        title: Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(color: AppTheme.textSecondary.withValues(alpha: 0.8), fontSize: 13),
              )
            : null,
        trailing: const Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary, size: 20),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          title: const Text('Choisir la langue', style: TextStyle(color: AppTheme.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.languages.length,
              itemBuilder: (context, index) {
                final lang = provider.languages[index];
                return ListTile(
                  title: Text(lang.native, style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: provider.currentLocale == lang.locale
                      ? const Icon(Icons.check, color: AppTheme.goldAccent)
                      : null,
                  onTap: () {
                    provider.changeLanguage(lang.locale);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
