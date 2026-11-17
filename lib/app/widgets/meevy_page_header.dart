
import 'package:flutter/material.dart';

import '../theme/meevy_theme.dart';

/*
 * Intestazione condivisa tra le schermate principali.
 *
 * Mantiene dimensione, colore e allineamento coerenti.
 * Le azioni a destra sono facoltative.
 */
class MeevyPageHeader extends StatelessWidget {
  const MeevyPageHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontSize: 27,
                fontWeight: FontWeight.w600,
                color: MeevyTheme.darkGreen,
                height: 1.15,
              ),
            ),
          ),

          if (actions.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...actions,
          ],
        ],
      ),
    );
  }
}
