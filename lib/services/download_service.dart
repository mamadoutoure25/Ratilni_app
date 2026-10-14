import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';
import '../models/reciter_model.dart';

class DownloadItem {
  final int surahId;
  final String surahName;
  final int reciterId;
  final String reciterName;
  final String filePath;

  DownloadItem({
    required this.surahId,
    required this.surahName,
    required this.reciterId,
    required this.reciterName,
    required this.filePath,
  });

  Map<String, dynamic> toJson() => {
    'surahId': surahId,
    'surahName': surahName,
    'reciterId': reciterId,
    'reciterName': reciterName,
    'filePath': filePath,
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    surahId: json['surahId'],
    surahName: json['surahName'],
    reciterId: json['reciterId'],
    reciterName: json['reciterName'],
    filePath: json['filePath'],
  );
}

class DownloadService {
  static const String _keyDownloads = 'downloads_list';
  final Dio _dio = Dio();
  final Map<String, double> _downloadProgress = {};

  Future<List<DownloadItem>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_keyDownloads);
    if (data == null) return [];
    
    return data.map((item) => DownloadItem.fromJson(json.decode(item))).toList();
  }

  Future<void> _saveDownloads(List<DownloadItem> downloads) async {
    final prefs = await SharedPreferences.getInstance();
    final data = downloads.map((item) => json.encode(item.toJson())).toList();
    await prefs.setStringList(_keyDownloads, data);
  }

  bool isDownloaded(List<DownloadItem> downloads, int surahId, int reciterId) {
    return downloads.any((item) => item.surahId == surahId && item.reciterId == reciterId);
  }
  
  double? getProgress(int surahId, int reciterId) {
    return _downloadProgress['${surahId}_$reciterId'];
  }

  Future<String?> downloadSurah({
    required Surah surah,
    required Reciter reciter,
    required String url,
    required Function(double) onProgress,
  }) async {
    final downloadKey = '${surah.id}_${reciter.id}';
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final quranDir = Directory('${dir.path}/quran_downloads');
      if (!await quranDir.exists()) {
        await quranDir.create(recursive: true);
      }

      final fileName = '${reciter.id}_${surah.id}.mp3';
      final filePath = '${quranDir.path}/$fileName';

      _downloadProgress[downloadKey] = 0.0;

      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[downloadKey] = progress;
            onProgress(progress);
          }
        },
      );

      _downloadProgress.remove(downloadKey);

      final newItem = DownloadItem(
        surahId: surah.id,
        surahName: surah.name,
        reciterId: reciter.id,
        reciterName: reciter.name,
        filePath: filePath,
      );

      final downloads = await getDownloads();
      downloads.removeWhere((item) => item.surahId == surah.id && item.reciterId == reciter.id);
      downloads.add(newItem);
      await _saveDownloads(downloads);

      return filePath;
    } catch (e) {
      _downloadProgress.remove(downloadKey);
      return null;
    }
  }

  Future<void> deleteDownload(int surahId, int reciterId) async {
    final downloads = await getDownloads();
    final itemIndex = downloads.indexWhere((item) => item.surahId == surahId && item.reciterId == reciterId);
    
    if (itemIndex != -1) {
      final item = downloads[itemIndex];
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      downloads.removeAt(itemIndex);
      await _saveDownloads(downloads);
    }
  }
}
