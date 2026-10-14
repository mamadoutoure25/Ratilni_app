import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_provider.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../core/cover_helper.dart';
import '../../services/download_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isLooping = false;
  double _currentSpeed = 1.0;
  bool _showLiveLyrics = true;

  final DownloadService _downloadService = DownloadService();
  List<DownloadItem> _downloads = [];

  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _loadDownloads();

    // Un seul abonnement, créé une fois (et non à chaque build).
    final player = context.read<AppProvider>().audioService.player;
    _isPlaying = player.playing;
    _currentSpeed = player.speed;
    _stateSub = player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
        _isBuffering = state.processingState == ProcessingState.buffering ||
            state.processingState == ProcessingState.loading;
      });
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDownloads() async {
    final downloads = await _downloadService.getDownloads();
    if (mounted) {
      setState(() => _downloads = downloads);
    }
  }

  Future<void> _handleDownload(
      BuildContext context, AppProvider provider) async {
    final surah = provider.currentSurah;
    final reciter = provider.currentReciter;
    if (surah == null || reciter == null) return;

    if (_downloadService.isDownloaded(_downloads, surah.id, reciter.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Déjà téléchargé !'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final server = reciter.moshaf.first.server;
    final url = server.endsWith('/')
        ? '$server${surah.id.toString().padLeft(3, '0')}.mp3'
        : '$server/${surah.id.toString().padLeft(3, '0')}.mp3';

    setState(() {});

    final result = await _downloadService.downloadSurah(
      surah: surah,
      reciter: reciter,
      url: url,
      onProgress: (progress) {
        if (mounted) setState(() {});
      },
    );

    if (result != null) {
      await _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Téléchargement terminé !'),
              backgroundColor: Colors.green),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erreur de téléchargement'),
            backgroundColor: Colors.red),
      );
    }
  }

  String _coverPath(int? surahId) {
    if (surahId == null) return 'assets/images/fond.png';
    return CoverHelper.getCoverForSurah(surahId) ?? 'assets/images/fond.png';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final surah = provider.currentSurah;
    final reciter = provider.currentReciter;
    final audioService = provider.audioService;

    _isLooping = audioService.player.loopMode == LoopMode.one;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond : la pochette, très floutée
          Image.asset(_coverPath(surah?.id), fit: BoxFit.cover),
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: AppTheme.background.withValues(alpha: 0.72),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(surah?.name),
                _buildModeSwitch(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: _showLiveLyrics
                          ? (surah != null
                          ? PlayerCenterLyrics(
                        surahId: surah.id,
                        serverUrl: (reciter != null &&
                            reciter.moshaf.isNotEmpty)
                            ? reciter.moshaf.first.server
                            : null,
                      )
                          : const SizedBox.shrink())
                          : _buildCover(surah?.id),
                    ),
                  ),
                ),
                _buildTrackInfo(provider, surah, reciter),
                const SizedBox(height: 12),
                _buildProgress(audioService),
                const SizedBox(height: 8),
                _buildControls(provider, audioService),
                const SizedBox(height: 24),
                _buildBottomActions(context, provider, audioService),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Haut de l'écran ─────────────────────────

  Widget _buildTopBar(String? surahName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronDown,
                color: AppTheme.textPrimary, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'En lecture',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  surahName ?? 'Sélectionnez une sourate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          // Équilibre visuel avec le bouton de gauche
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    Widget item(String label, bool selected, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppTheme.goldAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? AppTheme.background : AppTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            item('Texte', _showLiveLyrics,
                    () => setState(() => _showLiveLyrics = true)),
            item('Pochette', !_showLiveLyrics,
                    () => setState(() => _showLiveLyrics = false)),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(int? surahId) {
    return AnimatedScale(
      scale: _isPlaying ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.goldAccent.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 20),
              ),
            ],
            image: DecorationImage(
              image: AssetImage(_coverPath(surahId)),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Infos, progression, contrôles ─────────────────────────

  Widget _buildTrackInfo(AppProvider provider, dynamic surah, dynamic reciter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah?.name ?? 'Aucune sourate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34,
                    height: 1.05,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reciter?.name ?? 'Sélectionnez un récitateur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (surah != null)
            IconButton(
              icon: Icon(
                provider.isFavorite(surah.id)
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: provider.isFavorite(surah.id)
                    ? AppTheme.goldAccent
                    : AppTheme.textPrimary,
                size: 28,
              ),
              onPressed: () => provider.toggleFavorite(surah.id),
            ),
        ],
      ),
    );
  }

  Widget _buildProgress(dynamic audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<Duration>(
        stream: audioService.player.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final Duration total = audioService.player.duration ?? Duration.zero;
          final maxValue =
          total.inSeconds.toDouble() > 0 ? total.inSeconds.toDouble() : 1.0;

          return Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppTheme.goldAccent,
                  inactiveTrackColor:
                  AppTheme.textSecondary.withValues(alpha: 0.25),
                  thumbColor: AppTheme.goldAccent,
                  trackHeight: 4,
                  thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  min: 0.0,
                  max: maxValue,
                  value: position.inSeconds.toDouble().clamp(0.0, maxValue),
                  onChanged: (value) {
                    audioService.player.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Text(_formatDuration(total),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls(AppProvider provider, dynamic audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              LucideIcons.shuffle,
              color: provider.isShuffleMode
                  ? AppTheme.goldAccent
                  : AppTheme.textSecondary,
            ),
            onPressed: () => provider.toggleShuffle(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.skipBack,
                color: AppTheme.textPrimary, size: 34),
            onPressed: () => provider.previousSurah(),
          ),
          GestureDetector(
            onTap: () {
              if (_isBuffering) return;
              if (_isPlaying) {
                audioService.pause();
              } else {
                audioService.play();
              }
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.goldAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldAccent.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _isBuffering
                    ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                      color: AppTheme.background, strokeWidth: 3),
                )
                    : Icon(
                  _isPlaying ? LucideIcons.pause : LucideIcons.play,
                  color: AppTheme.background,
                  size: 34,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.skipForward,
                color: AppTheme.textPrimary, size: 34),
            onPressed: () => provider.nextSurah(),
          ),
          IconButton(
            icon: Icon(
              LucideIcons.repeat,
              color:
              _isLooping ? AppTheme.goldAccent : AppTheme.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isLooping = !_isLooping;
                audioService.player
                    .setLoopMode(_isLooping ? LoopMode.one : LoopMode.off);
              });
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────── Actions du bas ─────────────────────────

  Widget _buildBottomActions(
      BuildContext context, AppProvider provider, dynamic audioService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActionItem(
            LucideIcons.gauge,
            'Vitesse ${_currentSpeed}x',
            highlighted: _currentSpeed != 1.0,
            onTap: () {
              setState(() {
                if (_currentSpeed == 1.0) {
                  _currentSpeed = 1.25;
                } else if (_currentSpeed == 1.25) {
                  _currentSpeed = 1.5;
                } else if (_currentSpeed == 1.5) {
                  _currentSpeed = 2.0;
                } else if (_currentSpeed == 2.0) {
                  _currentSpeed = 0.5;
                } else {
                  _currentSpeed = 1.0;
                }
                audioService.player.setSpeed(_currentSpeed);
              });
            },
          ),
          _buildDownloadButton(context, provider),
          _buildActionItem(
            LucideIcons.timer,
            'Minuterie',
            onTap: () => _showComingSoon(context, 'La minuterie'),
          ),
          _buildActionItem(
            LucideIcons.fileText,
            'Traduction',
            onTap: () {
              final surah = provider.currentSurah;
              if (surah == null) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => LyricsModal(surahId: surah.id),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature sera disponible prochainement.'),
        backgroundColor: AppTheme.goldAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionItem(
      IconData icon,
      String label, {
        VoidCallback? onTap,
        bool highlighted = false,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: highlighted
                    ? AppTheme.goldAccent.withValues(alpha: 0.18)
                    : AppTheme.cardColor.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                highlighted ? AppTheme.goldAccent : AppTheme.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color:
                highlighted ? AppTheme.goldAccent : AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, AppProvider provider) {
    final surah = provider.currentSurah;
    final reciter = provider.currentReciter;

    if (surah == null || reciter == null) {
      return _buildActionItem(LucideIcons.download, 'Télécharger');
    }

    final isDownloaded =
    _downloadService.isDownloaded(_downloads, surah.id, reciter.id);
    final progress = _downloadService.getProgress(surah.id, reciter.id);

    if (progress != null) {
      return SizedBox(
        width: 64,
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: AppTheme.goldAccent,
                    backgroundColor:
                    AppTheme.textSecondary.withValues(alpha: 0.25),
                  ),
                  const Icon(LucideIcons.download,
                      color: AppTheme.goldAccent, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toInt()} %',
              style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return _buildActionItem(
      isDownloaded ? LucideIcons.checkCircle : LucideIcons.download,
      isDownloaded ? 'Téléchargé' : 'Télécharger',
      highlighted: isDownloaded,
      onTap: () => _handleDownload(context, provider),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// ═════════════════════════ Fenêtre des traductions ═════════════════════════

class LyricsModal extends StatefulWidget {
  final int surahId;
  const LyricsModal({super.key, required this.surahId});

  @override
  State<LyricsModal> createState() => _LyricsModalState();
}

class _LyricsModalState extends State<LyricsModal> {
  List<Map<String, String>> _verses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  Future<void> _loadLyrics() async {
    try {
      final client = ApiClient();
      final verses = await client.getSurahLyrics(widget.surahId);
      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Texte et traduction',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldAccent,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                child:
                CircularProgressIndicator(color: AppTheme.goldAccent))
                : _verses.isEmpty
                ? const Center(
              child: Text(
                'Textes non disponibles',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              itemCount: _verses.length,
              separatorBuilder: (context, index) => Divider(
                color: AppTheme.goldAccent.withValues(alpha: 0.15),
                height: 36,
              ),
              itemBuilder: (context, index) {
                final verse = _verses[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      verse['ar'] ?? '',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(
                        color: AppTheme.goldAccent,
                        fontSize: 26,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      verse['fr'] ?? '',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ Texte synchronisé au centre ═════════════════════════

class PlayerCenterLyrics extends StatefulWidget {
  final int surahId;
  final String? serverUrl;
  const PlayerCenterLyrics({super.key, required this.surahId, this.serverUrl});

  @override
  State<PlayerCenterLyrics> createState() => _PlayerCenterLyricsState();
}

class _PlayerCenterLyricsState extends State<PlayerCenterLyrics> {
  List<Map<String, String>> _verses = [];
  List<Map<String, dynamic>>? _timings;
  bool _isLoading = true;
  bool _hasBasmalahAdded = false;
  final PageController _pageController = PageController();
  StreamSubscription? _positionSubscription;
  int _currentVerseIndex = 0;

  bool _showArabic = true;
  bool _showPhonetic = true;
  bool _showFrench = true;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
    _setupLiveSync();
  }

  void _setupLiveSync() {
    final provider = context.read<AppProvider>();
    _positionSubscription =
        provider.audioService.player.positionStream.listen((position) {
          if (_timings != null && _timings!.isNotEmpty && _verses.isNotEmpty) {
            final millis = position.inMilliseconds;
            final indexInTimings = _timings!.indexWhere(
                    (t) => millis >= t['start_time'] && millis < t['end_time']);

            if (indexInTimings != -1) {
              final timing = _timings![indexInTimings];
              final ayahNum = timing['ayah'] as int;

              int targetPage = _hasBasmalahAdded ? ayahNum : ayahNum - 1;

              if (targetPage < 0) targetPage = 0;
              if (targetPage >= _verses.length) targetPage = _verses.length - 1;

              if (targetPage != _currentVerseIndex) {
                _currentVerseIndex = targetPage;
                if (_pageController.hasClients) {
                  _pageController.animateToPage(
                    targetPage,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              }
            }
          }
        });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PlayerCenterLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahId != widget.surahId ||
        oldWidget.serverUrl != widget.serverUrl) {
      _loadLyrics();
    }
  }

  Future<void> _loadLyrics() async {
    setState(() => _isLoading = true);
    try {
      final client = ApiClient();
      final verses = await client.getSurahLyrics(widget.surahId);

      List<Map<String, dynamic>>? timings;
      if (widget.serverUrl != null) {
        timings = await client.getAyatTiming(widget.serverUrl!, widget.surahId);
      }

      if (mounted) {
        bool addedBasmalah = false;
        if (timings != null &&
            timings.isNotEmpty &&
            timings.first['ayah'] == 0 &&
            widget.surahId != 1) {
          verses.insert(0, {
            'ar': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            'ph': 'Bismillāhi r-raḥmāni r-raḥīm',
            'fr':
            'Au nom d\'Allah, le Tout Miséricordieux, le Très Miséricordieux.',
          });
          addedBasmalah = true;
        }

        setState(() {
          _verses = verses;
          _timings = timings;
          _hasBasmalahAdded = addedBasmalah;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.goldAccent));
    }

    if (_verses.isEmpty) {
      return const Center(
        child: Text('Textes non disponibles',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    return Column(
      children: [
        // Choix des langues affichées
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLangToggle('Arabe', _showArabic,
                      (v) => setState(() => _showArabic = v)),
              const SizedBox(width: 8),
              _buildLangToggle('Phonétique', _showPhonetic,
                      (v) => setState(() => _showPhonetic = v)),
              const SizedBox(width: 8),
              _buildLangToggle('Français', _showFrench,
                      (v) => setState(() => _showFrench = v)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _verses.length,
            itemBuilder: (context, index) {
              final verse = _verses[index];
              return Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showArabic && verse['ar'] != null) ...[
                        Text(
                          verse['ar']!,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 30,
                            color: AppTheme.goldAccent,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (_showPhonetic && verse['ph'] != null) ...[
                        Text(
                          verse['ph']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 21,
                            color: AppTheme.textPrimary,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_showFrench && verse['fr'] != null) ...[
                        Text(
                          verse['fr']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Verset ${index + 1} sur ${_verses.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          AppTheme.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLangToggle(
      String label, bool isSelected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.goldAccent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.goldAccent
                : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.goldAccent : AppTheme.textSecondary,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}