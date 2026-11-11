
import 'package:flutter/material.dart';

/*
 * Tema grafico globale di Meevy.
 *
 * Centralizza i colori dell'applicazione per mantenere
 */
class MeevyTheme {
  MeevyTheme._();

  // Verde principale utilizzato anche nel Pomodoro.
  static const Color primaryGreen = Color(0xFF4D8B67);

  // Colori di supporto.
  static const Color background = Color(0xFFF7FAF7);
  static const Color lightGreen = Color(0xFFD9EBDD);
  static const Color darkGreen = Color(0xFF254B35);

  static ThemeData get light {
    /*
     * Genera una palette Material 3 a partire
     * dal verde scelto per Meevy.
     */
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: lightGreen,
      onPrimaryContainer: darkGreen,
      secondary: primaryGreen,
      onSecondary: Colors.white,
      secondaryContainer: lightGreen,
      surface: background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Sfondo generale delle schermate.
      scaffoldBackgroundColor: background,

      // Barre superiori.
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: darkGreen,
        scrolledUnderElevation: 0,
      ),

      // Barra di navigazione inferiore.
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFFEDF5EF),
        indicatorColor: lightGreen,
        elevation: 0,
      ),

      // Pulsanti principali.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Color(0xFFE0E6E1),
          disabledForegroundColor: Color(0xFF758078),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),

      // Pulsanti secondari.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(
            color: Color(0xFFAAC9B3),
          ),
        ),
      ),

      // Pulsanti testuali, ad esempio "Continua come ospite".
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryGreen,
        ),
      ),

      // Campi di testo del login e dei form.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD6E1D9),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryGreen,
            width: 2,
          ),
        ),
      ),

      // Cursore e selezione del testo.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: primaryGreen,
        selectionColor: lightGreen,
        selectionHandleColor: primaryGreen,
      ),

      // Indicatori di caricamento.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGreen,
      ),

      // Finestre di conferma, ad esempio "Annulla sessione?".
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Messaggi temporanei dell'app.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkGreen,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
