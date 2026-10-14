import 'package:flutter/material.dart';
import '../models/surah_model.dart';
import '../models/reciter_model.dart';
import '../models/language_model.dart';
import '../models/rewaya_model.dart';
import '../core/api_client.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class AppProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();

  List<Surah> _surahs = [];
  List<Reciter> _reciters = [];
  List<Language> _languages = [];
  List<Rewaya> _riwayat = [];
  List<int> _favoriteSurahIds = [];
  
  bool _isLoading = true;
  String? _error;

  Surah? _currentSurah;
  Reciter? _currentReciter;
  String _currentLocale = 'fr'; // default locale
  
  Language? _selectedLanguageFilter;
  Rewaya? _selectedRewayaFilter;
  Surah? _selectedSurahFilter;

  bool _isShuffleMode = false;

  List<Surah> get surahs => _surahs;
  List<Reciter> get reciters => _reciters;
  List<Language> get languages => _languages;
  List<Rewaya> get riwayat => _riwayat;
  List<int> get favoriteSurahIds => _favoriteSurahIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Surah? get currentSurah => _currentSurah;
  Reciter? get currentReciter => _currentReciter;
  AudioService get audioService => _audioService;
  bool get isShuffleMode => _isShuffleMode;
  String get currentLocale => _currentLocale;

  Language? get selectedLanguageFilter => _selectedLanguageFilter;
  Rewaya? get selectedRewayaFilter => _selectedRewayaFilter;
  Surah? get selectedSurahFilter => _selectedSurahFilter;

  AppProvider() {
    _audioService.player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _surahs.length) {
        _currentSurah = _surahs[index];
        notifyListeners();
      }
    });
  }

  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      _languages = await _apiClient.getLanguages();
      final savedLang = await _storageService.getLanguage();
      if (savedLang != null) {
        _currentLocale = savedLang;
      } else {
        final hasFr = _languages.any((l) => l.locale == 'fr');
        _currentLocale = hasFr ? 'fr' : (_languages.isNotEmpty ? _languages.first.locale : 'ar');
      }

      await _loadDataForLocale();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDataForLocale() async {
    _surahs = await _apiClient.getSurahs(_currentLocale);
    
    try {
      _riwayat = await _apiClient.getRiwayat(_currentLocale);
    } catch (e) {
      // API might fail for some locales, gracefully continue
      _riwayat = [];
    }

    _reciters = await _apiClient.getReciters(
      _selectedLanguageFilter?.locale ?? _currentLocale,
      sura: _selectedSurahFilter?.id,
      rewaya: _selectedRewayaFilter?.id,
    );
    _favoriteSurahIds = await _storageService.getFavorites();

    final lastReciterId = await _storageService.getLastReciterId();
    if (lastReciterId != null) {
      _currentReciter = _reciters.cast<Reciter?>().firstWhere(
        (r) => r?.id == lastReciterId,
        orElse: () => _reciters.isNotEmpty ? _reciters.first : null,
      );
    } else if (_reciters.isNotEmpty) {
      _currentReciter = _reciters.cast<Reciter?>().firstWhere(
        (r) => r?.id == 123, 
        orElse: () => _reciters.first,
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setReciterFilters({Language? language, Rewaya? rewaya, Surah? sura, bool clear = false}) async {
    if (clear) {
      _selectedLanguageFilter = null;
      _selectedRewayaFilter = null;
      _selectedSurahFilter = null;
    } else {
      if (language != null) _selectedLanguageFilter = language;
      if (rewaya != null) _selectedRewayaFilter = rewaya;
      if (sura != null) _selectedSurahFilter = sura;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final langCode = _selectedLanguageFilter?.locale ?? _currentLocale;
      _reciters = await _apiClient.getReciters(
        langCode,
        sura: _selectedSurahFilter?.id,
        rewaya: _selectedRewayaFilter?.id,
      );
    } catch (e) {
      _error = e.toString();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> changeLanguage(String newLocale) async {
    if (newLocale == _currentLocale) return;
    _currentLocale = newLocale;
    _isLoading = true;
    notifyListeners();
    
    await _storageService.saveLanguage(newLocale);
    try {
      await _loadDataForLocale();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void setReciter(Reciter reciter) {
    _currentReciter = reciter;
    _storageService.saveLastReciterId(reciter.id);
    notifyListeners();
  }

  Future<void> playSurah(Surah surah) async {
    _currentSurah = surah;
    notifyListeners();
    
    // Sécurité : si aucun récitateur n'est sélectionné, on prend le premier
    if (_currentReciter == null && _reciters.isNotEmpty) {
      _currentReciter = _reciters.first;
    }

    if (_currentReciter != null) {
      try {
        int initialIndex = _surahs.indexWhere((s) => s.id == surah.id);
        if (initialIndex == -1) initialIndex = 0;
        
        await _audioService.loadPlaylist(_currentReciter!, _surahs, initialIndex);
        await _audioService.play();
      } catch (e) {
        print("Erreur de lecture: $e");
      }
    }
  }

  void toggleShuffle() {
    _isShuffleMode = !_isShuffleMode;
    _audioService.player.setShuffleModeEnabled(_isShuffleMode);
    notifyListeners();
  }

  Future<void> nextSurah() async {
    await _audioService.player.seekToNext();
  }

  Future<void> previousSurah() async {
    await _audioService.player.seekToPrevious();
  }
  
  Future<void> toggleFavorite(int surahId) async {
    await _storageService.toggleFavorite(surahId);
    _favoriteSurahIds = await _storageService.getFavorites();
    notifyListeners();
  }
  
  bool isFavorite(int surahId) {
    return _favoriteSurahIds.contains(surahId);
  }
}
