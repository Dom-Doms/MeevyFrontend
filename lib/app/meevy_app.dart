
//import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/main_shell.dart';
import 'theme/meevy_theme.dart';




/*import '../features/subject/data/repositories/subjects_repository.dart';
import '../features/subject/presentation/screens/subjects_screen.dart';
import '../features/subject/presentation/view_models/subjects_view_model.dart';***/
import 'session/session_view_model.dart';

import '../features/auth/data/repositories/auth_repository.dart';
import '../features/auth/presentation/view_models/login_view_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/pomodoro/presentation/screens/guest_pomodoro_screen.dart';


/*
 * Configura l'applicazione Flutter e seleziona
 * le schermate in base allo stato di autenticazione.
 */
class MeevyApp extends StatefulWidget {
  const MeevyApp({super.key});

  @override
  State<MeevyApp> createState() => _MeevyAppState();
}

class _MeevyAppState extends State<MeevyApp> {
  @override
  void initState() {
    super.initState();

    // Verifica la sessione dopo il primo frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<SessionViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meevy',
      debugShowCheckedModeBanner: false,
      // Applica il tema verde a tutta Meevy.
      theme: MeevyTheme.light,
      home: Consumer<SessionViewModel>(
        builder: (context, session, _) {
          switch (session.status) {
            case SessionStatus.loading:
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );

            case SessionStatus.error:
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Impossibile verificare la sessione.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: session.initialize,
                        child: const Text('Riprova'),
                      ),
                    ],
                  ),
                ),
              );

            case SessionStatus.unauthenticated:
              return ChangeNotifierProvider(
                create: (context) => LoginViewModel(
                  context.read<AuthRepository>(),
                ),
                child: const LoginScreen(),
              );
            case SessionStatus.authenticated:
              return const MainShell();
            /*case SessionStatus.authenticated:
            questa logica è stata spostata in mainShell
              return ChangeNotifierProvider(
                create: (context) => SubjectsViewModel(
                  SubjectsRepository(context.read<Dio>()),
                )..load(),
                child: const SubjectsScreen(),
              );*/
            case SessionStatus.guest:
              return const GuestPomodoroScreen();
          }
        },
      ),
    );
  }
}
