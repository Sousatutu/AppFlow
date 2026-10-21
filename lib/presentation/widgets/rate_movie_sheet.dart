import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Abre o painel de avaliação (1 a 5 estrelas).
///
/// Retorna a nota escolhida, ou `null` se o usuário cancelar.
Future<int?> showRateMovieSheet(
  BuildContext context, {
  required String movieTitle,
  int? initialRating,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _RateMovieSheet(
      movieTitle: movieTitle,
      initialRating: initialRating,
    ),
  );
}

class _RateMovieSheet extends StatefulWidget {
  final String movieTitle;
  final int? initialRating;

  const _RateMovieSheet({
    required this.movieTitle,
    this.initialRating,
  });

  @override
  State<_RateMovieSheet> createState() => _RateMovieSheetState();
}

class _RateMovieSheetState extends State<_RateMovieSheet> {
  static const _labels = [
    '',
    'Ruim',
    'Regular',
    'Bom',
    'Muito bom',
    'Excelente'
  ];

  late int _rating = widget.initialRating ?? 0;

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRating != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ALÇA
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.stroke,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Sua avaliação',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              widget.movieTitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // ESTRELAS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;

                return IconButton(
                  onPressed: () => setState(() => _rating = value),
                  tooltip: value == 1 ? '1 estrela' : '$value estrelas',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  iconSize: 40,
                  icon: Icon(
                    value <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.starGold,
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 20,
              child: Text(
                _rating == 0
                    ? 'Toque nas estrelas para avaliar'
                    : '$_rating/5 · ${_labels[_rating]}',
                style: TextStyle(
                  color:
                      _rating == 0 ? AppTheme.textSecondary : AppTheme.starGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed:
                    _rating == 0 ? null : () => Navigator.pop(context, _rating),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  isEditing ? 'ATUALIZAR AVALIAÇÃO' : 'SALVAR AVALIAÇÃO',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}
