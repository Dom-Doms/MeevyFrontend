
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../session/session_view_model.dart';

import '../../features/subject/data/repositories/subjects_repository.dart';
import '../../features/subject/presentation/screens/subjects_screen.dart';
import '../../features/subject/presentation/view_models/subjects_view_model.dart';

import '../../features/pomodoro/data/repositories/pomodoro_repository.dart';
import '../../features/pomodoro/presentation/view_models/pomodoro_view_model.dart';
import '../../features/pomodoro/presentation/screens/pomodoro_screen.dart';

/*
 * Contenitore principale dell'utente autenticato.
 *
 * Gestisce la navigazione tra le sezioni dell'app,
 * mantenendo una barra inferiore sempre visibile.
 */
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // La tab Pomodoro è selezionata inizialmente.
  int _selectedIndex = 2;

  Widget _buildSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return ChangeNotifierProvider(
          create: (context) => SubjectsViewModel(
            SubjectsRepository(context.read<Dio>()),
          )..load(),
          child: const SubjectsScreen(),
        );

      case 1:
        return const _PlaceholderScreen(
          title: 'Gruppi',
          message: 'Qui gestiremo i gruppi di studio.',
        );

      case 2:
        return ChangeNotifierProvider(
          create: (context) => PomodoroViewModel(
            PomodoroRepository(context.read<Dio>()),
          )..loadCurrentSession(),
          child: const PomodoroScreen(),
        );

      case 3:
        return const _ProfileScreen();

      default:
        throw StateError('Tab non valida.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildSelectedPage(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Materie',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Gruppi',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}

/*
 * Schermata temporanea per le funzionalità
 * che implementeremo nei prossimi passaggi.
 */
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const _PlaceholderScreen({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(message)),
    );
  }
}

/*
 * Prima versione del profilo.
 * Per ora permette soltanto il logout.
 */
class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () {
            context.read<SessionViewModel>().logout();
          },
          icon: const Icon(Icons.logout),
          label: const Text('Esci'),
        ),
      ),
    );
  }
}
