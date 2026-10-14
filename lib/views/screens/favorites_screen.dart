import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import '../../core/cover_helper.dart';
import 'player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final favoriteSurahs =
    provider.surahs.where((s) => provider.isFavorite(s.id)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 24,
        title: Text(
          'Mes favoris',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldAccent,
          ),
        ),
      ),
      body: provider.isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.goldAccent),
      )
          : favoriteSurahs.isEmpty
          ? _buildEmpty()
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Text(
              favoriteSurahs.length == 1
                  ? '1 sourate'
                  : '${favoriteSurahs.length} sourates',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: favoriteSurahs.length,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemBuilder: (context, index) => _buildRow(
                  context, provider, favoriteSurahs[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.goldAccent.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(LucideIcons.heart,
                  size: 36, color: AppTheme.goldAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun favori pour le moment',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Appuyez sur le cœur dans le lecteur pour retrouver ici vos sourates préférées.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, AppProvider provider, dynamic surah) {
    final place = surah.isMakki ? 'Mekkoise' : 'Médinoise';
    final cover =
        CoverHelper.getCoverForSurah(surah.id) ?? 'assets/images/fond.png';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        provider.playSurah(surah);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: AssetImage(cover),
                  fit: BoxFit.cover,
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
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${surah.id} · $place · Page ${surah.startPage}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Retirer des favoris',
              icon: const Icon(Icons.favorite,
                  color: AppTheme.goldAccent, size: 22),
              onPressed: () => provider.toggleFavorite(surah.id),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppTheme.goldAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.play,
                  color: AppTheme.background, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}