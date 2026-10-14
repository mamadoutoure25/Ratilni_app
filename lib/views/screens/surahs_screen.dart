import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import 'player_screen.dart';

class SurahsScreen extends StatefulWidget {
  const SurahsScreen({super.key});

  @override
  State<SurahsScreen> createState() => _SurahsScreenState();
}

class _SurahsScreenState extends State<SurahsScreen> {
  static const _tabs = ['Toutes', 'Mekkoises', 'Médinoises'];

  String _searchQuery = '';
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final query = _searchQuery.trim().toLowerCase();

    final surahs = provider.surahs.where((s) {
      final matchesSearch = s.name.toLowerCase().contains(query) ||
          s.id.toString() == query;
      if (_selectedTabIndex == 1) return matchesSearch && s.isMakki;
      if (_selectedTabIndex == 2) return matchesSearch && !s.isMakki;
      return matchesSearch;
    }).toList();

    // Affiche le bouton retour seulement si l'écran a été ouvert par-dessus un autre.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        )
            : null,
        centerTitle: false,
        titleSpacing: canPop ? 0 : 24,
        title: Text(
          'Sourates',
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
          _buildTabs(),
          Expanded(
            child: provider.isLoading
                ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            )
                : surahs.isEmpty
                ? _buildEmpty()
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: surahs.length,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemBuilder: (context, index) =>
                  _buildRow(context, provider, surahs[index]),
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
                  hintText: 'Nom ou numéro de sourate',
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

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final selected = _selectedTabIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedTabIndex = i),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                        color: selected
                            ? AppTheme.goldAccent
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    color: selected
                        ? AppTheme.goldAccent
                        : AppTheme.cardColor,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.searchX,
              size: 48, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Aucune sourate trouvée',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Essayez un autre nom ou un autre numéro.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppProvider provider, dynamic surah) {
    final isCurrent = provider.currentSurah?.id == surah.id;
    final place = surah.isMakki ? 'Mekkoise' : 'Médinoise';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        provider.playSurah(surah);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.goldAccent
                      : AppTheme.goldAccent.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Text(
                surah.id.toString(),
                style: TextStyle(
                  color: isCurrent ? AppTheme.goldAccent : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                      isCurrent ? AppTheme.goldAccent : AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$place · Page ${surah.startPage}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isCurrent ? LucideIcons.audioLines : LucideIcons.play,
              color: AppTheme.goldAccent,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}