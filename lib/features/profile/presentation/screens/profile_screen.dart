
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/session/session_view_model.dart';
import '../../data/models/user_profile.dart';
import '../view_models/profile_view_model.dart';
import '../../../../app/widgets/meevy_page_header.dart';

//Schermata del profilo personale.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, _) {
            // Primo caricamento.
            if (viewModel.isLoading &&
                viewModel.profile == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final profile = viewModel.profile;

            // Errore iniziale: non abbiamo dati da mostrare.
            if (profile == null) {
              return _buildError(context, viewModel);
            }

            return _buildProfile(context, viewModel, profile);
          },
        ),
      ),
    );
  }

  /*
   * Mostra un errore quando il profilo
   * non è stato ancora recuperato.
   */
  Widget _buildError(
      BuildContext context,
      ProfileViewModel viewModel,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),

            Text(
              viewModel.errorMessage ??
                  'Impossibile caricare il profilo.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: viewModel.loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                context.read<SessionViewModel>().logout();
              },
              child: const Text('Esci'),
            ),
          ],
        ),
      ),
    );
  }

  //Contenuto principale della schermata.

  Widget _buildProfile(
      BuildContext context,
      ProfileViewModel viewModel,
      UserProfile profile,
      ) {
    final colors = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: viewModel.loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [

          MeevyPageHeader(
            title: 'Il mio profilo',
            actions: [
              IconButton(
                tooltip: 'Aggiorna profilo',
                onPressed: viewModel.isLoading
                    ? null
                    : viewModel.loadProfile,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),



          const SizedBox(height: 24),

          // Riepilogo con avatar generato dalle iniziali.
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      profile.initials,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Durante un aggiornamento conserviamo
          // visibili i dati già recuperati.
          if (viewModel.isLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],

          if (viewModel.errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text(viewModel.errorMessage!),
                trailing: TextButton(
                  onPressed: viewModel.loadProfile,
                  child: const Text('Riprova'),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),

          Text(
            'Account',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.person_outline,
                  label: 'Nome',
                  value: _optionalText(profile.firstName),
                ),

                const Divider(height: 1, indent: 64),

                _infoTile(
                  icon: Icons.person_outline,
                  label: 'Cognome',
                  value: _optionalText(profile.lastName),
                ),

                const Divider(height: 1, indent: 64),

                _infoTile(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: profile.email,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Informazioni account',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 12),

          Card(
            elevation: 0,
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.badge_outlined,
                  label: 'Ruolo',
                  value: profile.roleLabel,
                ),

                const Divider(height: 1, indent: 64),

                _infoTile(
                  icon: Icons.verified_user_outlined,
                  label: 'Stato account',
                  value: profile.statusLabel,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Riutilizza il logout già gestito
          // dal SessionViewModel globale.
          OutlinedButton.icon(
            onPressed: () {
              context.read<SessionViewModel>().logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text('Esci dall’account'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error),
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /*
   * Riga riutilizzabile per visualizzare
   * una singola informazione dell'account.
   */
  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  String _optionalText(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Non indicato' : text;
  }
}
