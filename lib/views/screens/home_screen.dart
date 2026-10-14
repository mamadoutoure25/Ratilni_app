import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import '../../core/cover_helper.dart';
import 'reciters_screen.dart';
import 'player_screen.dart';
import 'downloads_screen.dart';
import 'surahs_screen.dart';

/// Petite donnée statique pour les rails horizontaux.
class _Pick {
  final int surahId;
  final String title;
  final String reciter;
  const _Pick(this.surahId, this.title, this.reciter);
}

const _resumePicks = [
  _Pick(1, 'Al-Fatiha', 'Mishary Alafasy'),
  _Pick(2, 'Al-Baqarah', 'Yasser Al-Dosari'),
  _Pick(18, 'Al-Kahf', 'Saad Al Ghamdi'),
];

const _recommendedPicks = [
  _Pick(3, 'Al-Imran', 'Saad Al Ghamdi'),
  _Pick(4, 'An-Nisa', 'AbdulBaset'),
  _Pick(36, 'Ya-Sin', 'Mishary Alafasy'),
  _Pick(55, 'Ar-Rahman', 'Mishary Alafasy'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _fallbackCover = 'assets/images/fond.png';

  String _cover(int surahId) =>
      CoverHelper.getCoverForSurah(surahId) ?? _fallbackCover;

  Future<void> _play(BuildContext context, int surahId) async {
    final provider = context.read<AppProvider>();
    if (provider.surahs.isEmpty) return;
    final surah = provider.surahs.firstWhere(
      (s) => s.id == surahId,
      orElse: () => provider.surahs.first,
    );
    await provider.playSurah(surah);
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.goldAccent),
            )
          : Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildHeader(context, provider)),
                      SliverToBoxAdapter(child: _buildSearch(context)),
                      SliverToBoxAdapter(child: _buildHero(context, provider)),
                      SliverToBoxAdapter(child: _buildVerse()),
                      SliverToBoxAdapter(
                        child: _buildRail(
                          context,
                          title: 'Pour reprendre',
                          picks: _resumePicks,
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildShortcuts(context)),
                      SliverToBoxAdapter(
                        child: _buildRail(
                          context,
                          title: 'À écouter ensuite',
                          picks: _recommendedPicks,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: provider.currentSurah != null ? 120 : 40,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildMiniPlayer(context, provider),
              ],
            ),
    );
  }

  // ───────────────────────── En-tête ─────────────────────────

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As-salamu alaykum',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quran Audio',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 38,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          _buildLanguagePicker(provider),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker(AppProvider provider) {
    return PopupMenuButton<String>(
      tooltip: 'Changer de langue',
      icon: const Icon(LucideIcons.globe, color: AppTheme.textPrimary, size: 22),
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: provider.changeLanguage,
      itemBuilder: (context) {
        return provider.languages.map((lang) {
          final selected = provider.currentLocale == lang.locale;
          return PopupMenuItem<String>(
            value: lang.locale,
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: selected
                      ? const Icon(LucideIcons.check,
                          color: AppTheme.goldAccent, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  lang.native,
                  style: TextStyle(
                    color: selected ? AppTheme.goldAccent : AppTheme.textPrimary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  // ───────────────────────── Recherche ─────────────────────────

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SurahsScreen()),
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.search,
                  color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Rechercher une sourate',
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.9),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Carte principale ─────────────────────────

  Widget _buildHero(BuildContext context, AppProvider provider) {
    final current = provider.currentSurah;
    final int surahId = current?.id ?? _resumePicks.first.surahId;
    final String title = current?.name ?? _resumePicks.first.title;
    final String reciter = provider.currentReciter?.name ?? _resumePicks.first.reciter;
    final String label = current != null ? 'Reprendre l\'écoute' : 'Commencer par';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: GestureDetector(
        onTap: () => current != null
            ? Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              )
            : _play(context, surahId),
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            image: DecorationImage(
              image: AssetImage(_cover(surahId)),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.background.withValues(alpha: 0.92),
                ],
                stops: const [0.3, 1.0],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reciter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.play,
                          color: AppTheme.background, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        current != null ? 'Ouvrir le lecteur' : 'Écouter',
                        style: const TextStyle(
                          color: AppTheme.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Verset du jour ─────────────────────────

  Widget _buildVerse() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verset du jour',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Et en vérité, dans le rappel d\'Allah, les cœurs trouvent la sérénité.',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24,
                      height: 1.3,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sourate Ar-Ra\'d, 13:28',
                    style: TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Rails horizontaux ─────────────────────────

  Widget _buildRail(
    BuildContext context, {
    required String title,
    required List<_Pick> picks,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 212,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: picks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, i) => _buildPickCard(context, picks[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickCard(BuildContext context, _Pick pick) {
    return GestureDetector(
      onTap: () => _play(context, pick.surahId),
      child: SizedBox(
        width: 148,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: AssetImage(_cover(pick.surahId)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: AppTheme.goldAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.play,
                        color: AppTheme.background, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pick.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pick.reciter,
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
    );
  }

  // ───────────────────────── Raccourcis ─────────────────────────

  Widget _buildShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildShortcut(
              icon: LucideIcons.mic2,
              title: 'Récitateurs',
              subtitle: 'Choisir une voix',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecitersScreen()),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildShortcut(
              icon: LucideIcons.downloadCloud,
              title: 'Hors-ligne',
              subtitle: 'Sourates téléchargées',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.goldAccent, size: 24),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── Mini lecteur ─────────────────────────

  Widget _buildMiniPlayer(BuildContext context, AppProvider provider) {
    final surah = provider.currentSurah;
    if (surah == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.cardColor.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.goldAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      image: DecorationImage(
                        image: AssetImage(_cover(surah.id)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          surah.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.currentReciter?.name ?? 'Lecture en cours',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: provider.audioService.player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? LucideIcons.pause : LucideIcons.play,
                          color: AppTheme.goldAccent,
                          size: 26,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            provider.audioService.player.pause();
                          } else {
                            provider.audioService.player.play();
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
