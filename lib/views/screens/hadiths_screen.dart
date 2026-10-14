import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../models/hadith_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HadithsScreen extends StatefulWidget {
  const HadithsScreen({super.key});

  @override
  State<HadithsScreen> createState() => _HadithsScreenState();
}

class _HadithsScreenState extends State<HadithsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Hadith> _hadiths = [];
  bool _isLoading = true;

  // Contrôleur pour gérer le texte de la barre de recherche
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultHadiths(); // Charge une sélection de Hadiths au démarrage
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Charge une liste de Hadiths célèbres (ex: l'intention, etc.) avec tous les détails
  Future<void> _loadDefaultHadiths() async {
    setState(() => _isLoading = true);
    try {
      // On utilise les IDs récupérés dans la documentation pour avoir des exemples riches
      final results = await _apiClient.getDetailedHadiths(['4560', '2962', '4494', '5833']);
      setState(() {
        _hadiths = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors du chargement des Hadiths.');
    }
  }

  // Lance une recherche sur l'API (qui utilise désormais la méthode enrichie dans ApiClient)
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      // Si la recherche est vide, on remet la liste par défaut
      _loadDefaultHadiths();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _apiClient.searchHadiths(query.trim(), languageCode: 'fr');
      setState(() {
        _hadiths = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Aucun résultat ou erreur de connexion.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hadiths',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- BARRE DE RECHERCHE ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  icon: const Icon(LucideIcons.search, color: AppTheme.goldAccent, size: 20),
                  hintText: 'Rechercher un thème (ex: jeûne...)',
                  hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
                  border: InputBorder.none,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _loadDefaultHadiths();
                      FocusScope.of(context).unfocus(); // Ferme le clavier
                    },
                  )
                      : null,
                ),
                onSubmitted: _performSearch,
                onChanged: (value) {
                  // Met à jour l'UI pour afficher ou cacher la croix (suffixIcon)
                  setState(() {});
                },
              ),
            ),
          ),

          // --- LISTE DES RÉSULTATS ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
                : _hadiths.isEmpty
                ? Center(
              child: Text(
                'Aucun Hadith trouvé.',
                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7)),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _hadiths.length,
              itemBuilder: (context, index) {
                final hadith = _hadiths[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.goldAccent.withOpacity(0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre et Grade (Authentique, etc.)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              hadith.title,
                              style: const TextStyle(
                                color: AppTheme.goldAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (hadith.grade.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.goldAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
                              ),
                              child: Text(
                                hadith.grade,
                                style: const TextStyle(
                                  color: AppTheme.goldAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ]
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Texte du Hadith
                      Text(
                        hadith.text,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      // Attribution (ex: Rapporté par Al Bukhârî et Muslim)
                      if (hadith.attribution.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          hadith.attribution,
                          style: TextStyle(
                            color: AppTheme.goldAccent.withOpacity(0.8),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],

                      // Explication (affichée uniquement si elle existe)
                      if (hadith.explanation.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: Colors.white10, height: 1),
                        ),
                        Row(
                          children: [
                            const Icon(LucideIcons.info, color: AppTheme.textSecondary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Explication',
                              style: TextStyle(
                                color: AppTheme.textSecondary.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hadith.explanation,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}