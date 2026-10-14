import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import '../../core/cover_helper.dart';
import '../../services/download_service.dart';
import 'player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _downloadService = DownloadService();
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final downloads = await _downloadService.getDownloads();
    if (mounted) {
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(DownloadItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Supprimer le téléchargement ?',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          '${item.surahName} (${item.reciterName}) ne sera plus disponible hors ligne.',
          style: const TextStyle(color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteDownload(item);
    }
  }

  Future<void> _deleteDownload(DownloadItem item) async {
    await _downloadService.deleteDownload(item.surahId, item.reciterId);
    await _loadDownloads();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.surahName} supprimée.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _play(DownloadItem item) async {
    final provider = context.read<AppProvider>();
    if (provider.surahs.isEmpty) return;

    final surah = provider.surahs.firstWhere(
          (s) => s.id == item.surahId,
      orElse: () => provider.surahs.first,
    );

    // Limite actuelle : le récitateur n'est pas changé si celui du
    // téléchargement diffère du récitateur sélectionné.
    await provider.playSurah(surah);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Hors-ligne',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.goldAccent,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.goldAccent),
      )
          : _downloads.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildEmptyState() {
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
              child: const Icon(LucideIcons.downloadCloud,
                  size: 36, color: AppTheme.goldAccent),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune sourate téléchargée',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Téléchargez des sourates depuis le lecteur pour les écouter sans connexion.',
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

  Widget _buildList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
          child: Text(
            _downloads.length == 1
                ? '1 sourate disponible hors ligne'
                : '${_downloads.length} sourates disponibles hors ligne',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            itemCount: _downloads.length,
            itemBuilder: (context, index) => _buildRow(_downloads[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(DownloadItem item) {
    final cover = CoverHelper.getCoverForSurah(item.surahId) ??
        'assets/images/fond.png';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _play(item),
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
                    item.surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle,
                          size: 13, color: AppTheme.goldAccent),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.reciterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(LucideIcons.trash2,
                  color: AppTheme.textSecondary, size: 20),
              onPressed: () => _confirmDelete(item),
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