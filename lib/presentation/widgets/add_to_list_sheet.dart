import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../data/models/movie_model.dart';
import '../../providers/movie_provider.dart';

Future<void> showAddToListSheet(BuildContext context, Movie movie) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddToListSheet(movie: movie),
  );
}

class _AddToListSheet extends StatefulWidget {
  final Movie movie;

  const _AddToListSheet({required this.movie});

  @override
  State<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends State<_AddToListSheet> {
  bool _inWatchlist = false;
  List<Map<String, dynamic>> _userLists = [];
  Set<int> _selectedListIds = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final provider = context.read<MovieProvider>();
      _inWatchlist = provider.isInWatchlist(widget.movie.tmdbId);

      final lists = await provider.getUserLists();
      final currentListIds =
          await provider.getListIdsForMovie(widget.movie.tmdbId);

      if (mounted) {
        setState(() {
          _userLists = lists;
          _selectedListIds = Set<int>.from(currentListIds);
        });
      }
    } catch (error) {
      debugPrint('Erro ao carregar listas do Supabase: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar listas: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final provider = context.read<MovieProvider>();

      // 1. Atualiza a lista padrão "Quero Ver" (Watchlist)
      final currentlyInWatchlist = provider.isInWatchlist(widget.movie.tmdbId);
      if (_inWatchlist != currentlyInWatchlist) {
        await provider.toggleWatchlist(widget.movie);
      }

      // 2. Atualiza os vínculos com as listas personalizadas
      await provider.updateMovieCustomLists(
        widget.movie,
        _selectedListIds.toList(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Listas de "${widget.movie.title}" atualizadas!'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      debugPrint('Erro ao salvar filme na lista: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ALÇA SUPERIOR
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.stroke,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TÍTULO
            const Text(
              'Salvar em qual lista?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
              )
            else ...[
              // LISTA PADRÃO: QUERO VER
              CheckboxListTile(
                value: _inWatchlist,
                activeColor: AppTheme.accent,
                checkColor: const Color(0xFF071018),
                title: const Text(
                  'Quero Ver (Favoritos)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Lista principal do seu perfil',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                onChanged: (val) {
                  setState(() => _inWatchlist = val ?? false);
                },
              ),

              const Divider(color: AppTheme.stroke),

              // LISTAS PERSONALIZADAS
              if (_userLists.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Você ainda não criou listas personalizadas. Crie uma na aba Perfil!',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _userLists.length,
                    itemBuilder: (context, index) {
                      final list = _userLists[index];
                      final listId = list['id'] as int;
                      final isSelected = _selectedListIds.contains(listId);

                      return CheckboxListTile(
                        value: isSelected,
                        activeColor: AppTheme.accent,
                        checkColor: const Color(0xFF071018),
                        title: Text(
                          list['name'] ?? 'Minha Lista',
                          style: const TextStyle(fontSize: 13),
                        ),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedListIds.add(listId);
                            } else {
                              _selectedListIds.remove(listId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              // BOTÃO SALVAR
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: const Color(0xFF071018),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF071018),
                          ),
                        )
                      : const Text(
                          'SALVAR SELEÇÃO',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
