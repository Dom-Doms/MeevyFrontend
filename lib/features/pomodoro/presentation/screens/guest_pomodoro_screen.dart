import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/session/session_view_model.dart';

class GuestPomodoroScreen extends StatelessWidget {
  const GuestPomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro ospite')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, size: 64),
            const SizedBox(height: 16),

            const Text('Pomodoro personale'),
            const SizedBox(height: 8),

            const Text('Qui realizzeremo il timer locale.'),

            const SizedBox(height: 24),

            OutlinedButton(
              onPressed: () {
                context.read<SessionViewModel>().exitGuestMode();
              },
              child: const Text('Torna al login'),
            ),
          ],
        ),
      ),
    );
  }
}
