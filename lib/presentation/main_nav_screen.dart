import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/models/movie_model.dart';
import 'screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import 'widgets/rate_movie_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/settings_screen.dart';
import 'widgets/add_to_list_sheet.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _HomeTab(
        onMovieTap: (movie) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MovieDetailScreen(movie: movie),
            ),
          );
        },
      ),
      _SearchTab(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      _WatchedTab(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      _StatusTab(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      _ProfileTab(
        onBack: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Assistidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// ======================================================
// HOME
// ======================================================

class _HomeTab extends StatelessWidget {
  final ValueChanged<Movie> onMovieTap;

  const _HomeTab({
    required this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);

    // 1. MOSTRA ÍCONE DE CARREGAMENTO ENQUANTO BUSCA OS FILMES
    if (movieProvider.isLoading && movieProvider.movies.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    // 2. MOSTRA MENSAGEM DE ERRO SE A API DO TMDB FALHAR
    if (movieProvider.errorMessage != null && movieProvider.movies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off,
                  size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text(
                movieProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => movieProvider.loadMovies(),
                child: const Text('Tentar Novamente'),
              )
            ],
          ),
        ),
      );
    }

    final populares = movieProvider.movies;

    final avaliados = [...movieProvider.movies]
      ..sort((a, b) => b.rating.compareTo(a.rating));

    // Seleciona um filme diferente conforme o dia.
    final hoje = DateTime.now();
    final diaDoAno = hoje.difference(DateTime(hoje.year, 1, 1)).inDays;

    final filmeDestaque = movieProvider.movies.isEmpty
        ? null
        : movieProvider.movies[diaDoAno % movieProvider.movies.length];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        // Cabeçalho
        Row(
          children: [
            const Expanded(
              child: Row(
                children: [
                  Text(
                    'ENIC',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  )
                ],
              ),
            ),
            IconButton(
              tooltip: 'Configurações',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Filme em destaque
        if (filmeDestaque != null)
          _FeaturedMovie(
            movie: filmeDestaque,
            onTap: () => onMovieTap(filmeDestaque),
          ),

        const SizedBox(height: 22),

        // Populares
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Populares no Brasil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 205,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: populares.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = populares[index];

              return SizedBox(
                width: 105,
                child: _PopularMovieCard(
                  movie: movie,
                  onTap: () => onMovieTap(movie),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 22),

        // Mais bem avaliados
        const Text(
          'Mais Bem Avaliados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...avaliados.map(
          (movie) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TopRatedMovieCard(
              movie: movie,
              onTap: () => onMovieTap(movie),
            ),
          ),
        ),
      ],
    );
  }
}

// ======================================================
// BANNER DE DESTAQUE
// ======================================================

class _FeaturedMovie extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _FeaturedMovie({
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 178,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE66B20),
            Color(0xFF8F3515),
            Color(0xFF151D28),
          ],
          stops: [0.0, 0.48, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    movie.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    },
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.45, 1.0],
                        colors: [
                          Color(0xFF8F3515),
                          Color(0x558F3515),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🔥 EM DESTAQUE',
                    style: TextStyle(
                      color: Color(0xFF071018),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  movie.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${movie.year} · ${movie.runtime} · ${movie.genres.join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE0E4EA),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: AppTheme.starGold,
                    ),
                    Text(
                      ' ${movie.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppTheme.starGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        movie.streamingProvider,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF071018),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                      ),
                      child: const Text(
                        'DETALHES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// CARD DOS FILMES POPULARES
// ======================================================

class _PopularMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _PopularMovieCard({
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // CAPA DO FILME
                    Image.network(
                      movie.posterUrl ?? '',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) {
                          return child;
                        }

                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.accent,
                            strokeWidth: 2,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.surface,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.movie_outlined,
                            color: AppTheme.textSecondary,
                            size: 35,
                          ),
                        );
                      },
                    ),

                    // GRADIENTE PARA MELHORAR A LEITURA
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33000000),
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                        ),
                      ),
                    ),

                    // NOTA DO FILME
                    Positioned(
                      top: 7,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10151D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '★ ${movie.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            color: AppTheme.starGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${movie.year} · ${movie.genres.first}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
// ======================================================
// CARD DOS MAIS BEM AVALIADOS
// ======================================================

// ======================================================
// CARD DOS MAIS BEM AVALIADOS (CORRIGIDO PARA EVITAR OVERFLOW)
// ======================================================

class _TopRatedMovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _TopRatedMovieCard({
    required this.movie,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9),
                  color: const Color(0xFF203F72),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.network(
                    movie.posterUrl ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.movie,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${movie.year} · ${movie.genres.join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.starGold,
                          size: 16,
                        ),
                        // EXPANDED E ELLIPSIS ADICIONADOS PARA EVITAR O OVERFLOW
                        Expanded(
                          child: Text(
                            ' ${movie.rating.toStringAsFixed(1)} · ${movie.streamingProvider}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<MovieProvider>(
                builder: (context, provider, child) {
                  final favorito = provider.isInWatchlist(movie.tmdbId);

                  return IconButton(
                    onPressed: () => showAddToListSheet(context, movie),
                    icon: Icon(
                      favorito
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: AppTheme.accent,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// DETALHES DO FILME (COM SINOPSE, ONDE ASSISTIR E PRIORIZAÇÃO DE ASSINATURAS)
// ======================================================

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  late Movie _currentMovie;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _currentMovie = widget.movie;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    try {
      final repository = context.read<MovieProvider>().repository;
      final fullMovie = await repository.getMovieById(
        widget.movie.tmdbId,
        type: widget.movie.type,
      );

      if (fullMovie != null && mounted) {
        setState(() {
          _currentMovie = fullMovie.copyWith(
            id: widget.movie.id,
            watched: widget.movie.watched,
            userRating: widget.movie.userRating,
            status: widget.movie.status,
            hasReview: widget.movie.hasReview,
            watchedAt: widget.movie.watchedAt,
          );
          _loadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = _currentMovie;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // CAPA E CABEÇALHO
          SliverAppBar(
            expandedHeight: 220,
            pinned: false,
            automaticallyImplyLeading: false,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE66B20),
                          Color(0xFF8F3515),
                          AppTheme.background,
                        ],
                      ),
                    ),
                  ),

                  Center(
                    child: Image.network(
                      movie.posterUrl ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.movie,
                          size: 80,
                          color: Colors.white54,
                        );
                      },
                    ),
                  ),

                  // BOTÕES SUPERIORES
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailHeaderButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.pop(context),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _detailHeaderButton(
                                icon: Icons.home_outlined,
                                onTap: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Consumer<MovieProvider>(
                                builder: (context, provider, child) {
                                  final isFavorite =
                                      provider.isInWatchlist(movie.tmdbId);

                                  return _detailHeaderButton(
                                    icon: isFavorite
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    onTap: () {
                                      showAddToListSheet(context, movie);

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFavorite
                                                ? '${movie.title} removido dos favoritos.'
                                                : '${movie.title} adicionado aos favoritos.',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // INFORMAÇÕES DO FILME
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '${movie.year} · ${movie.runtime} · ${movie.genres.join(', ')}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ONDE ASSISTIR NO BRASIL (COM PRIORIDADE PARA OS SERVIÇOS ASSINADOS)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Onde Assistir no Brasil',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TMDB',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_loadingDetails)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.accent,
                        ),
                      ),
                    )
                  else if (movie.watchProviders.isEmpty)
                    _streamingChip('Indisponível', isSubscribed: false)
                  else
                    Builder(
                      builder: (context) {
                        final userSubs =
                            context.watch<MovieProvider>().userSubscriptions;

                        // Reordena para que os serviços que o usuário assina fiquem no topo/início
                        final sortedProviders =
                            List<String>.from(movie.watchProviders);
                        sortedProviders.sort((a, b) {
                          final aIsSub = userSubs.any((s) =>
                              a.toLowerCase().contains(s.toLowerCase()) ||
                              s.toLowerCase().contains(a.toLowerCase()));
                          final bIsSub = userSubs.any((s) =>
                              b.toLowerCase().contains(s.toLowerCase()) ||
                              s.toLowerCase().contains(b.toLowerCase()));
                          if (aIsSub && !bIsSub) return -1;
                          if (!aIsSub && bIsSub) return 1;
                          return 0;
                        });

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: sortedProviders.map((provider) {
                              final isSubscribed = userSubs.any((s) =>
                                  provider
                                      .toLowerCase()
                                      .contains(s.toLowerCase()) ||
                                  s.toLowerCase().contains(
                                      provider.toLowerCase()));

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _streamingChip(
                                  provider,
                                  isSubscribed: isSubscribed,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 18),

                  // NOTA DO TMDB E SUA AVALIAÇÃO
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151E29),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF202D3D),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'NOTA TMDB',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    movie.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    ' /5',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: const Color(0xFF26364A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SUA AVALIAÇÃO',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Consumer<MovieProvider>(
                                builder: (context, provider, child) {
                                  final userRating =
                                      provider.userRatingFor(movie.tmdbId);

                                  if (userRating == null) {
                                    return const Text(
                                      'Ainda não avaliado',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    );
                                  }

                                  final stars = userRating.isInfinite
                                      ? userRating.round().clamp(0, 5).toInt()
                                      : 0;
                                  final filled = '★' * stars;
                                  final empty = '☆' * (5 - stars);

                                  return Text(
                                    '$filled$empty',
                                    style: const TextStyle(
                                      color: AppTheme.starGold,
                                      fontSize: 14,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Consumer<MovieProvider>(
                          builder: (context, provider, child) {
                            final rated =
                                provider.userRatingFor(movie.tmdbId) != null;

                            return OutlinedButton(
                              onPressed: () => _openRatingSheet(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.accent,
                                side: const BorderSide(
                                  color: AppTheme.accent,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 9,
                                ),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                rated ? '★ EDITAR' : '★ AVALIAR',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SINOPSE REAL
                  const Text(
                    'Sinopse',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    (movie.synopsis != null &&
                            movie.synopsis!.trim().isNotEmpty)
                        ? movie.synopsis!
                        : 'Sinopse não disponível para este título em português.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // BOTÃO JÁ ASSISTIDO / AVALIAR
                  Consumer<MovieProvider>(
                    builder: (context, provider, child) {
                      final watched = provider.isWatched(movie.tmdbId);
                      final rated =
                          provider.userRatingFor(movie.tmdbId) != null;

                      final label = rated
                          ? 'EDITAR MINHA NOTA'
                          : watched
                              ? 'ADICIONAR NOTA'
                              : 'JÁ ASSISTIDO (ADICIONAR NOTA)';

                      return SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: FilledButton.icon(
                          onPressed: () => _openRatingSheet(context),
                          icon: Icon(
                            rated
                                ? Icons.edit_outlined
                                : Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xCC202020),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            color: Colors.white,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget _streamingChip(String provider, {bool isSubscribed = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: isSubscribed
            ? AppTheme.accent.withValues(alpha: 0.15)
            : const Color(0xFF151E29),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSubscribed ? AppTheme.accent : const Color(0xFF26364A),
          width: isSubscribed ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSubscribed ? Icons.check_circle : Icons.play_circle_outline,
            color: AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 7),
          Text(
            provider,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSubscribed ? FontWeight.bold : FontWeight.w600,
              color: isSubscribed ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRatingSheet(BuildContext context) async {
    final provider = context.read<MovieProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final rating = await showRateMovieSheet(
      context,
      movieTitle: _currentMovie.title,
      initialRating: provider.userRatingFor(_currentMovie.tmdbId)?.round(),
    );

    if (rating == null) return;

    final saved = await provider.rateMovie(_currentMovie, rating.toDouble());

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Você deu $rating/5 para ${_currentMovie.title}.'
              : 'Não foi possível salvar sua avaliação. Tente novamente.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ======================================================
// BUSCAR
// ======================================================

class _SearchTab extends StatefulWidget {
  final VoidCallback onBack;

  const _SearchTab({
    required this.onBack,
  });

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController _controller = TextEditingController();

  String _query = '';
  String _filtroSelecionado = 'Todos';

  final List<String> _filtros = [
    'Todos',
    'Filmes',
    'Séries',
    'Diretores',
    'Assinaturas',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàãâä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòõôö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    final userSubs = provider.userSubscriptions;

    final listaBase =
        _query.trim().isEmpty ? provider.movies : provider.searchResults;

    final resultados = listaBase.where((movie) {
      if (_filtroSelecionado == 'Filmes') {
        return movie.type == 'Filme';
      } else if (_filtroSelecionado == 'Séries') {
        return movie.type == 'Série';
      } else if (_filtroSelecionado == 'Diretores') {
        if (_query.trim().isEmpty) return movie.director != 'Indisponível';
        return _normalize(movie.director).contains(_normalize(_query)) ||
            _normalize(movie.title).contains(_normalize(_query));
      } else if (_filtroSelecionado == 'Assinaturas') {
        if (userSubs.isEmpty) return false;

        // Coleta todas as plataformas disponíveis para este título
        final List<String> moviePlatforms = [];
        if (movie.streamingProvider.isNotEmpty &&
            movie.streamingProvider != 'Indisponível') {
          moviePlatforms.add(movie.streamingProvider);
        }
        moviePlatforms.addAll(movie.watchProviders);

        // Se o título não está em nenhum serviço conhecido, oculta
        if (moviePlatforms.isEmpty) return false;

        // Verifica se pelo menos uma das plataformas bate com as assinaturas do usuário
        return moviePlatforms.any((platform) {
          final normPlatform = _normalize(platform);
          return userSubs.any((sub) {
            final normSub = _normalize(sub);
            return normPlatform.contains(normSub) ||
                normSub.contains(normPlatform);
          });
        });
      }
      return true;
    }).toList();

    return Column(
      children: [
        // BARRA DE PESQUISA
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _controller,
            onChanged: (val) {
              setState(() => _query = val);
              provider.searchMovies(val);
            },
            decoration: InputDecoration(
              hintText: 'Buscar filmes, séries ou diretores...',
              prefixIcon: const Icon(
                Icons.search, 
                color: AppTheme.accent),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                        provider.searchMovies('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF151E29),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // CHIPS DE FILTRO (ROLAGEM HORIZONTAL)
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtros.length,
            itemBuilder: (context, index) {
              final filtro = _filtros[index];
              final isSelected = _filtroSelecionado == filtro;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filtro,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.accent,
                  backgroundColor: const Color(0xFF151E29),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.accent
                          : const Color(0xFF26364A),
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _filtroSelecionado = filtro);
                    }
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // LISTA DE RESULTADOS
        Expanded(
          child: provider.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                )
              : resultados.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhum título encontrado.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: resultados.length,
                      itemBuilder: (context, index) {
                        return MovieCard(movie: resultados[index]);
                      },
                    ),
        ),
      ],
    );
  }
}

// ======================================================
// MOVIE CARD (Utilizado na grade de busca)
// ======================================================

class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailScreen(movie: movie),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  movie.posterUrl ?? '',
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.movie_outlined,
                        color: AppTheme.textSecondary,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${movie.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// ASSISTIDOS
// ======================================================

class _WatchedTab extends StatefulWidget {
  final VoidCallback onBack;

  const _WatchedTab({
    required this.onBack,
  });

  @override
  State<_WatchedTab> createState() => _WatchedTabState();
}

class _WatchedTabState extends State<_WatchedTab> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  bool _mostRecentFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data não informada';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();

    final assistidos = provider.watchedMovies.where((movie) {
      return movie.title.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    assistidos.sort((a, b) {
      final dateA = a.watchedAt ?? DateTime(1900);
      final dateB = b.watchedAt ?? DateTime(1900);

      return _mostRecentFirst ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
    });

    final quantidade = provider.watchedMovies.length;

    final minutosTotais = provider.watchedMovies.fold<int>(
      0,
      (total, movie) {
        final minutos = int.tryParse(
              movie.runtime.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              ),
            ) ??
            0;

        return total + minutos;
      },
    );

    final horas = minutosTotais ~/ 60;
    final minutos = minutosTotais % 60;

    final media = quantidade == 0
        ? 0.0
        : provider.watchedMovies.fold<double>(
              0,
              (total, movie) => total + movie.rating,
            ) /
            quantidade;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 20, 24),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                tooltip: 'Voltar para Home',
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Já Assistidos',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // RESUMO DOS FILMES ASSISTIDOS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _WatchedMetric(
                      value: '$quantidade',
                      label: 'FILMES VISTOS',
                    ),
                  ),
                  Expanded(
                    child: _WatchedMetric(
                      value: '${horas}h ${minutos}min',
                      label: 'TEMPO TOTAL',
                    ),
                  ),
                  Expanded(
                    child: _WatchedMetric(
                      value: media.toStringAsFixed(1),
                      label: 'MÉDIA DAS NOTAS',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // CAMPO DE PESQUISA
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar nos assistidos...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.accent,
              ),
              suffixIcon: _query.isNotEmpty
              ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                  });
                },
                icon: const Icon(Icons.clear, size: 20),
              )
              : null,
              filled: true,
              fillColor: const Color(0xFF151E29),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none
              ),
            ),
          ),
        ),

        // ORDENAÇÃO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${assistidos.length} filmes encontrados',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _mostRecentFirst = !_mostRecentFirst;
                  });
                },
                icon: const Icon(Icons.sort, size: 18),
                label: Text(
                  _mostRecentFirst ? 'Mais recentes' : 'Mais antigos',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        // LISTA DE FILMES
        Expanded(
          child: assistidos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum filme assistido encontrado.',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    24,
                  ),
                  itemCount: assistidos.length,
                  itemBuilder: (context, index) {
                    final movie = assistidos[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                movie.posterUrl ?? '',
                                width: 92,
                                height: 132,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 92,
                                    height: 132,
                                    color: Colors.black26,
                                    child: const Icon(
                                      Icons.movie,
                                      size: 36,
                                      color: AppTheme.accent,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          movie.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(
                                          Icons.more_vert,
                                        ),
                                        onSelected: (value) {
                                          if (value == 'remove') {
                                            provider.toggleWatched(
                                              movie,
                                            );
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'remove',
                                            child: Text(
                                              'Remover dos assistidos',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${movie.year} · ${movie.runtime}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Assistido em: '
                                    '${_formatDate(movie.watchedAt)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    movie.streamingProvider,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 17,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        movie.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: movie.genres
                                        .map(
                                          (genre) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              genre,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        movie.hasReview
                                            ? Icons.rate_review
                                            : Icons.edit_note,
                                        size: 16,
                                        color: movie.hasReview
                                            ? AppTheme.accent
                                            : Colors.white54,
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          movie.hasReview
                                              ? 'Avaliação registrada'
                                              : 'Sem avaliação escrita',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _WatchedMetric extends StatelessWidget {
  final String value;
  final String label;

  const _WatchedMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

// ======================================================
// ESTATÍSTICAS GLOBAIS
// ======================================================

class _StatusTab extends StatelessWidget {
  final VoidCallback onBack;

  const _StatusTab({
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);
    final assistidos = movieProvider.watchedMovies;

    final totalFilmes = assistidos.length;
    final tempoMinutos = assistidos.fold<int>(
      0,
      (total, movie) {
        final minutos = int.tryParse(
              movie.runtime.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;

        return total + minutos;
      },
    );

    final horas = tempoMinutos ~/ 60;
    final minutos = tempoMinutos % 60;

    final avaliados = assistidos.where((movie) => movie.hasReview).length;

    final mediaNotas = assistidos.isEmpty
        ? 0.0
        : assistidos.fold<double>(
              0,
              (total, movie) => total + movie.rating,
            ) /
            assistidos.length;

    final generos = <String, int>{};

    for (final movie in assistidos) {
      for (final genero in movie.genres) {
        generos[genero] = (generos[genero] ?? 0) + 1;
      }
    }

    final generosOrdenados = generos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final cores = [
      const Color(0xFF00D9E8),
      const Color(0xFFAD83FF),
      const Color(0xFFFF6268),
      const Color(0xFFFFC629),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 20, 24),
      children: [
        // Cabeçalho com botão de voltar
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Voltar para Home',
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Text(
                'Estatística & Status',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Indicadores principais (Tempo Total & Avaliados)
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.schedule,
                iconColor: const Color(0xFF00D9E8),
                value: '${horas}h',
                subtitle: '$horas horas e $minutos minutos',
                label: 'TEMPO ASSISTIDO',
                labelColor: const Color(0xFF00D9E8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.star,
                iconColor: const Color(0xFFFFC629),
                value: '$avaliados',
                suffix: ' títulos',
                subtitle: 'Média de ${mediaNotas.toStringAsFixed(1)} ★',
                label: 'AVALIADOS',
                labelColor: const Color(0xFFFFC629),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Meta Global de Cinema
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _statusBoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Meta de Cinema',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '$totalFilmes / ${movieProvider.watchlistMovies.length} filmes',
                    style: const TextStyle(
                      color: Color(0xFF00D9E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: movieProvider.watchlistMovies.isNotEmpty
                    ? (totalFilmes / movieProvider.watchlistMovies.length).clamp(0.0, 1.0)
                    : 0.0,
                  minHeight: 12,
                  backgroundColor: const Color(0xFF252F3E),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00BFFF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você já completou ${totalFilmes > 0 && movieProvider.watchlistMovies.isNotEmpty
                ? ((totalFilmes / movieProvider.watchlistMovies.length)* 100).round()
                : 0.0}% da sua meta de ${movieProvider.watchlistMovies.length} filmes!',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8796A9),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Gêneros mais assistidos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _statusBoxDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gêneros Mais Assistidos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              if (generosOrdenados.isEmpty)
                const Text(
                  'Nenhum gênero disponível.',
                  style: TextStyle(color: Color(0xFF8796A9)),
                )
              else
                ...generosOrdenados.take(4).toList().asMap().entries.map(
                  (item) {
                    final indice = item.key;
                    final genero = item.value;

                    final percentual =
                        totalFilmes == 0 ? 0.0 : genero.value / totalFilmes;

                    final cor = cores[indice % cores.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  genero.key,
                                  style: const TextStyle(
                                    color: Color(0xFF8796A9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${(percentual * 100).round()}% (${genero.value})',
                                style: TextStyle(
                                  color: cor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: percentual.clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: const Color(0xFF252F3E),
                              valueColor: AlwaysStoppedAnimation<Color>(cor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? suffix;
  final String subtitle;
  final String label;
  final Color labelColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.subtitle,
    required this.label,
    required this.labelColor,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(12),
      decoration: _statusBoxDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (suffix != null)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 3, bottom: 2),
                    child: Text(
                      suffix!,
                      style: const TextStyle(
                        color: Color(0xFF8796A9),
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8796A9),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _statusBoxDecoration() {
  return BoxDecoration(
    color: const Color(0xFF151E29),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: const Color(0xFF202D3D),
      width: 1,
    ),
  );
}
// ======================================================
// PERFIL
// ======================================================

// ======================================================
// PERFIL DINÂMICO
// ======================================================

class _ProfileTab extends StatelessWidget {
  final VoidCallback? onBack;

  const _ProfileTab({
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);

    // Obtém o usuário logado via Supabase
    final user = Supabase.instance.client.auth.currentUser;
    final fullName =
        user?.userMetadata?['full_name'] as String? ?? 'Usuário Enic';
    final email = user?.email ?? 'usuario@email.com';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    // Estatísticas reais vindas do MovieProvider
    final watchedCount = movieProvider.watchedMovies.length;
    final watchlistCount = movieProvider.watchlistMovies.length;
    final reviewsCount =
        movieProvider.watchedMovies.where((m) => m.hasReview).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 20, 24),
      children: [
        // CABEÇALHO
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
              tooltip: 'Voltar',
            ),
            const SizedBox(width: 15),
            const Text(
              'Meu Perfil',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // CARTÃO DO USUÁRIO LOGADO
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.accent,
                            Color(0xFF0878D1),
                          ],
                        ),
                        border: Border.all(
                          color: AppTheme.accent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Membro Enic',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppTheme.stroke),
                const SizedBox(height: 8),

                // ESTATÍSTICAS REAIS
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        value: '$watchedCount',
                        label: 'Assistidos',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height: 38,
                      child: VerticalDivider(
                        color: AppTheme.stroke,
                        width: 1,
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openWatchlistScreen(context),
                        child: _ProfileMetric(
                          value: '$watchlistCount',
                          label: 'Quero Ver ➔',
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 38,
                      child: VerticalDivider(
                        color: AppTheme.stroke,
                        width: 1,
                      ),
                    ),
                    Expanded(
                      child: _ProfileMetric(
                        value: '$reviewsCount',
                        label: 'Reviews',
                        color: AppTheme.starGold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // MINHAS LISTAS PERSONALIZADAS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Minhas Listas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showCreateListDialog(context),
              icon: const Icon(
                Icons.add,
                size: 16,
                color: AppTheme.accent,
              ),
              label: const Text(
                'Nova',
                style: TextStyle(
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        FutureBuilder<List<Map<String, dynamic>>>(
          future: movieProvider.getUserLists(),
          builder: (context, snapshot) {
            final lists = snapshot.data ?? [];
            if (lists.isEmpty) {
              return const Text(
                'Nenhuma lista personalizada criada ainda.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                final listId = list['id'] as int;
                final listName = list['name'] ?? 'Minha Lista';

                return InkWell(
                  onTap: () => _openCustomListScreen(context, listId, listName),
                  borderRadius: BorderRadius.circular(16),
                  child: _ProfileListCard(
                    icon: Icons.movie_filter_outlined,
                    title: listName,
                    subtitle: 'Lista Personalizada',
                    iconColor: AppTheme.accent,
                  ),
                );
              },
            );
          },
        ),

        const SizedBox(height: 24),

        // EDITAR PERFIL
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text(
              'EDITAR DADOS DO PERFIL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // TELA DE VER FILMES DA LISTA "QUERO VER" (FAVORITOS)
  void _openWatchlistScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Minha Lista: Quero Ver')),
          body: Consumer<MovieProvider>(
            builder: (context, provider, child) {
              final favorites = provider.watchlistMovies;
              if (favorites.isEmpty) {
                return const Center(
                  child: Text(
                    'Você ainda não adicionou nenhum filme aos favoritos.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final movie = favorites[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Image.network(
                        movie.posterUrl ?? '',
                        width: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.movie, size: 40),
                      ),
                      title: Text(movie.title),
                      subtitle: Text('${movie.year} · ${movie.genres.first}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => provider.toggleWatchlist(movie),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCreateListDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Nova Lista Personalizada'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Nome da lista',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              final userId = Supabase.instance.client.auth.currentUser?.id;

              if (name.isNotEmpty && userId != null) {
                try {
                  await Supabase.instance.client.from('lists').insert({
                    'user_id': userId,
                    'name': name,
                    'description': '',
                  });

                  if (context.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lista "$name" criada com sucesso!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar lista: $e')),
                    );
                  }
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF071018),
            ),
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  void _openCustomListScreen(
      BuildContext context, int listId, String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomListDetailScreen(
          listId: listId,
          listName: listName,
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _ProfileMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ProfileListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _ProfileListCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// TELA DE EXIBIÇÃO DA LISTA PERSONALIZADA
// ======================================================

class CustomListDetailScreen extends StatefulWidget {
  final int listId;
  final String listName;

  const CustomListDetailScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<CustomListDetailScreen> createState() => _CustomListDetailScreenState();
}

class _CustomListDetailScreenState extends State<CustomListDetailScreen> {
  late Future<List<Movie>> _moviesFuture;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  void _loadMovies() {
    setState(() {
      _moviesFuture =
          context.read<MovieProvider>().getMoviesFromList(widget.listId);
    });
  }

  Future<void> _removeItem(Movie movie) async {
    try {
      await context
          .read<MovieProvider>()
          .removeMovieFromCustomList(widget.listId, movie.tmdbId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${movie.title}" removido da lista.'),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadMovies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmDeleteList(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Excluir lista?'),
        content: Text(
          'Tem certeza de que deseja excluir a lista "${widget.listName}"? '
          'Todos os filmes vinculados a ela serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Fecha o diálogo
              try {
                await context
                    .read<MovieProvider>()
                    .deleteCustomList(widget.listId);
                if (mounted) {
                  Navigator.pop(
                      context); // Fecha a tela da lista e volta para o Perfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Lista "${widget.listName}" excluída com sucesso!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir lista: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4545),
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.listName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // BOTÃO DE MAIS OPÇÕES (3 PONTINHOS) NA BARRA SUPERIOR
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDeleteList(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Color(0xFFFF4545),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Excluir lista',
                      style: TextStyle(
                        color: Color(0xFFFF4545),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }

          final movies = snapshot.data ?? [];

          if (movies.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum filme adicionado a esta lista ainda.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              final generoOuTipo =
                  movie.genres.isNotEmpty && movie.genres.first.isNotEmpty
                      ? movie.genres.first
                      : movie.type;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.stroke,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // PÔSTER ARREDONDADO
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                              ? Image.network(
                                  movie.posterUrl!,
                                  width: 44,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 44,
                                    height: 56,
                                    color: const Color(0xFF1F2C3D),
                                    child: const Icon(
                                      Icons.movie,
                                      color: AppTheme.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 56,
                                  color: const Color(0xFF1F2C3D),
                                  child: const Icon(
                                    Icons.movie,
                                    color: AppTheme.textSecondary,
                                    size: 22,
                                  ),
                                ),
                    ),
                    const SizedBox(width: 12),

                    // TÍTULO E ANO/GÊNERO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${movie.year} · $generoOuTipo',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // REMOVER FILME INDIVIDUAL DA LISTA
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFFF4545),
                        size: 22,
                      ),
                      onPressed: () => _removeItem(movie),
                      tooltip: 'Remover da lista',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
