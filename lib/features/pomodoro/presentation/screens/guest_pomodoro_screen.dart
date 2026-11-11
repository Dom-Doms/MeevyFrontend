import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/guest_pomodoro_timer.dart';

import '../../../../app/session/session_view_model.dart';

class GuestPomodoroScreen extends StatelessWidget {
  const GuestPomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro ospite')),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer locale, indipendente dal backend.
              const GuestPomodoroTimer(),

              const SizedBox(height: 28),

              // Torna al login senza creare un account Guest.
              OutlinedButton.icon(
                onPressed: () {
                  context.read<SessionViewModel>().exitGuestMode();
                },
                icon: const Icon(Icons.login),
                label: const Text('Torna al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
