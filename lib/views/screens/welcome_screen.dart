import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme.dart';
import 'main_layout.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image de fond
          Image.asset(
            'assets/images/image_acceuil.png',
            fit: BoxFit.cover,
          ),
          // Dégradé : l'image reste visible en haut, le texte repose sur le vert profond
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.background.withValues(alpha: 0.25),
                  AppTheme.background.withValues(alpha: 0.55),
                  AppTheme.background.withValues(alpha: 0.96),
                  AppTheme.background,
                ],
                stops: const [0.0, 0.35, 0.68, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
              // Un seul mouvement : tout le contenu apparaît en fondu au lancement
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - t)),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basmala, élément central de l'écran
                    Center(
                      child: Text(
                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 30,
                          height: 1.6,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Quran\nAudio',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 68,
                        height: 0.95,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Écoute. Réfléchis. Vis mieux.',
                      style: TextStyle(
                        fontSize: 17,
                        color: AppTheme.textPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Verset
                    IntrinsicHeight(
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
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Et Nous avons certes rendu le Coran facile pour le rappel.',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 21,
                                    height: 1.3,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Sourate Al-Qamar, 54:17',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.goldAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const MainLayout(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.goldAccent,
                          foregroundColor: AppTheme.background,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(29),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(LucideIcons.arrowRight,
                                size: 20, color: AppTheme.background),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}