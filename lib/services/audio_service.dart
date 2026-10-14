import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/reciter_model.dart';
import '../models/surah_model.dart';
import 'package:audiotags/audiotags.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get player => _player;

  String _formatSurahNumber(int id) {
    return id.toString().padLeft(3, '0');
  }

  Future<void> loadPlaylist(Reciter reciter, List<Surah> surahs, int initialIndex) async {
    if (reciter.moshaf.isEmpty) return;
    
    final server = reciter.moshaf.first.server;
    final dir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${dir.path}/quran_downloads');
    
    List<AudioSource> audioSources = [];

    for (var surah in surahs) {
      final fileName = '${_formatSurahNumber(surah.id)}.mp3';
      final localFileName = '${reciter.id}_${surah.id}.mp3';
      final localPath = '${quranDir.path}/$localFileName';
      
      final url = server.endsWith('/') ? '$server$fileName' : '$server/$fileName';
      
      // On pointe directement vers votre dossier cover_sourate
      // IMPORTANT : Il faudra renommer vos images en "1.png", "2.png", etc. 
      // pour que le code puisse les trouver dynamiquement selon l'ID de la sourate.
      final artUri = Uri.parse('asset:///assets/images/cover_sourate/${surah.id}.png');
      
      final mediaItem = MediaItem(
        id: '${reciter.id}_${surah.id}',
        album: reciter.name,
        title: surah.name,
        artist: reciter.name,
        artUri: artUri,
      );

      if (File(localPath).existsSync()) {
        audioSources.add(AudioSource.file(
          localPath,
          tag: mediaItem,
        ));
      } else {
        audioSources.add(AudioSource.uri(
          Uri.parse(url),
          tag: mediaItem,
        ));
      }
    }

    await _player.setAudioSource(ConcatenatingAudioSource(children: audioSources), initialIndex: initialIndex);
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }
  
  Future<void> stop() async {
    await _player.stop();
  }
}
