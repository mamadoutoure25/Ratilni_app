import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';

enum FilterType { surah, rewaya, language }

class RecitersScreen extends StatefulWidget {
  const RecitersScreen({super.key});

  @override
  State<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends State<RecitersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final query = _searchQuery.trim().toLowerCase();
    final reciters = provider.reciters
        .where((r) => r.name.toLowerCase().contains(query))
        .toList();

    final hasFilters = provider.selectedSurahFilter != null ||
        provider.selectedRewayaFilter != null ||
        provider.selectedLanguageFilter != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Text(
          'Récitateurs',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldAccent,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildFilters(provider, hasFilters),
          if (!provider.isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  reciters.length == 1
                      ? '1 récitateur'
                      : '${reciters.length} récitateurs',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            )
                : reciters.isEmpty
                ? _buildEmpty(hasFilters, provider)
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: reciters.length,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemBuilder: (context, index) =>
                  _buildRow(provider, reciters[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.search,
                color: AppTheme.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style:
                const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                cursorColor: AppTheme.goldAccent,
                decoration: InputDecoration(
                  hintText: 'Rechercher un récitateur',
                  hintStyle: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(AppProvider provider, bool hasFilters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Row(
        children: [
          _buildFilterChip(
            icon: LucideIcons.bookOpen,
            label: provider.selectedSurahFilter?.name ?? 'Sourate',
            isActive: provider.selectedSurahFilter != null,
            onTap: () => _showFilterSheet(context, FilterType.surah, provider),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: LucideIcons.audioLines,
            label: provider.selectedRewayaFilter?.name ?? 'Lecture',
            isActive: provider.selectedRewayaFilter != null,
            onTap: () => _showFilterSheet(context, FilterType.rewaya, provider),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: LucideIcons.globe,
            label: provider.selectedLanguageFilter?.native ?? 'Langue',
            isActive: provider.selectedLanguageFilter != null,
            onTap: () =>
                _showFilterSheet(context, FilterType.language, provider),
          ),
          if (hasFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => provider.setReciterFilters(clear: true),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: const Row(
                  children: [
                    Icon(LucideIcons.x,
                        size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Effacer',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? AppTheme.goldAccent : AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.goldAccent.withValues(alpha: 0.15)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.goldAccent : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool hasFilters, AppProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX,
              size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Aucun récitateur trouvé',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => provider.setReciterFilters(clear: true),
              child: const Text(
                'Effacer les filtres',
                style: TextStyle(color: AppTheme.goldAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(AppProvider provider, dynamic reciter) {
    final isSelected = provider.currentReciter?.id == reciter.id;
    final total =
    reciter.moshaf.isNotEmpty ? reciter.moshaf.first.surahTotal : 114;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => provider.setReciter(reciter),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldAccent.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldAccent.withValues(alpha: 0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isSelected
                  ? AppTheme.goldAccent
                  : AppTheme.cardColor,
              child: Text(
                reciter.name.isNotEmpty
                    ? reciter.name[0].toUpperCase()
                    : 'R',
                style: GoogleFonts.cormorantGaramond(
                  color: isSelected
                      ? AppTheme.background
                      : AppTheme.goldAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.goldAccent
                          : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$total sourates',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(LucideIcons.checkCircle,
                  color: AppTheme.goldAccent, size: 24),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(
      BuildContext context, FilterType type, AppProvider provider) {
    List items = [];
    String title = '';

    if (type == FilterType.surah) {
      items = provider.surahs;
      title = 'Choisir une sourate';
    } else if (type == FilterType.rewaya) {
      items = provider.riwayat;
      title = 'Choisir une lecture (rewaya)';
    } else if (type == FilterType.language) {
      items = provider.languages;
      title = 'Choisir une langue';
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aucun élément disponible pour ce filtre.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      color: AppTheme.goldAccent,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    String name = '';
                    bool isSelected = false;

                    if (type == FilterType.surah) {
                      name = item.name;
                      isSelected = provider.selectedSurahFilter?.id == item.id;
                    } else if (type == FilterType.rewaya) {
                      name = item.name;
                      isSelected =
                          provider.selectedRewayaFilter?.id == item.id;
                    } else if (type == FilterType.language) {
                      name = item.native;
                      isSelected =
                          provider.selectedLanguageFilter?.locale == item.locale;
                    }

                    return ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(
                        name,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.goldAccent
                              : AppTheme.textPrimary,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(LucideIcons.check,
                          color: AppTheme.goldAccent)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        if (type == FilterType.surah) {
                          provider.setReciterFilters(
                            sura: item,
                            rewaya: provider.selectedRewayaFilter,
                            language: provider.selectedLanguageFilter,
                          );
                        } else if (type == FilterType.rewaya) {
                          provider.setReciterFilters(
                            rewaya: item,
                            sura: provider.selectedSurahFilter,
                            language: provider.selectedLanguageFilter,
                          );
                        } else if (type == FilterType.language) {
                          provider.setReciterFilters(
                            language: item,
                            sura: provider.selectedSurahFilter,
                            rewaya: provider.selectedRewayaFilter,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}