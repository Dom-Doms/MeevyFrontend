
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/group_message.dart';
import '../view_models/group_chat_view_model.dart';

/*
 * Interfaccia della chat di gruppo.
 * La logica di comunicazione resta nel ViewModel.
 */
class GroupChatView extends StatefulWidget {
  const GroupChatView({super.key});

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    final viewModel = context.read<GroupChatViewModel>();

    final success = await viewModel.sendMessage(text);

    if (!mounted) return;

    if (success) {
      _messageController.clear();

      // Dopo l'invio torna agli ultimi messaggi.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scrollController.hasClients) return;

        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    } else if (viewModel.sendError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.sendError!)),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupChatViewModel>();

    if (viewModel.isLoading && viewModel.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.initialize,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Stato della connessione in tempo reale.
        if (!viewModel.isConnected)
          Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_outlined,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notifiche in tempo reale non connesse.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aggiorna chat',
                    onPressed: viewModel.refresh,
                    icon: const Icon(
                      Icons.refresh,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (viewModel.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh),
              label: Text(viewModel.errorMessage!),
            ),
          ),

        Expanded(
          child: viewModel.messages.isEmpty
              ? const Center(
            child: Text(
              'Nessun messaggio.\n'
                  'Inizia la conversazione!',
              textAlign: TextAlign.center,
            ),
          )
              : ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(12),
            itemCount: viewModel.messages.length +
                (viewModel.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // In cima all'elenco carica la cronologia.
              if (index == viewModel.messages.length) {
                return Center(
                  child: TextButton(
                    onPressed: viewModel.isLoadingOlder
                        ? null
                        : viewModel.loadOlder,
                    child: Text(
                      viewModel.isLoadingOlder
                          ? 'Caricamento...'
                          : 'Carica messaggi precedenti',
                    ),
                  ),
                );
              }

              // reverse:true mostra gli ultimi in basso.
              final message = viewModel.messages[
              viewModel.messages.length - 1 - index];

              final isMine =
                  message.senderUserId ==
                      viewModel.currentUserId;

              return _MessageBubble(
                message: message,
                isMine: isMine,
              );
            },
          ),
        ),

        // Campo di composizione.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !viewModel.isSending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    textCapitalization:
                    TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton.filled(
                  tooltip: 'Invia messaggio',
                  onPressed: viewModel.isSending
                      ? null
                      : _sendMessage,
                  icon: viewModel.isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/*
 * Rappresentazione grafica di un singolo messaggio.
 * I propri messaggi sono allineati a destra.
 */
class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMine;

  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final time = TimeOfDay.fromDateTime(
      message.createdAt.toLocal(),
    ).format(context);

    final senderName = message.senderName.isEmpty
        ? 'Utente'
        : message.senderName;

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.80,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMine
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMine) ...[
                Text(
                  senderName,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],

              Text(message.content),

              const SizedBox(height: 4),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
