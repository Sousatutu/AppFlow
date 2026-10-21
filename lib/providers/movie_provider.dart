import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/movie_model.dart';
import '../data/repositories/movie_repository.dart';

class MovieProvider extends ChangeNotifier {
  final MovieRepository repository;
  final _supabase = Supabase.instance.client;

  MovieProvider({required this.repository});

  List<Movie> _movies = []; // Filmes em Alta (TMDB)
  List<Movie> _watchedMovies = []; // Assistidos (Supabase)
  List<Movie> _watchlistMovies = []; // Quero Assistir / Favoritos (Supabase)
  List<Movie> _searchResults = []; // Resultados da Busca

  bool _isLoading = false;
  String? _errorMessage;

  List<Movie> get movies => List.unmodifiable(_movies);
  List<Movie> get watchedMovies => List.unmodifiable(_watchedMovies);
  List<Movie> get watchlistMovies => List.unmodifiable(_watchlistMovies);
  List<Movie> get searchResults => List.unmodifiable(_searchResults);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> loadMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Busca os filmes populares no TMDB
      _movies = await repository.getTrendingMovies();

      // 2. Busca os filmes assistidos e favoritos salvos no Supabase
      if (_userId != null) {
        _watchedMovies = await repository.getWatchedMovies(_userId!);
        _watchlistMovies = await repository.getWatchlistMovies(_userId!);
      }
    } catch (error) {
      _errorMessage = 'Erro de conexão. Verifique sua internet.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // GERENCIAMENTO DE ASSISTIDOS
  // ======================================================

  bool isWatched(int tmdbId) {
    return _watchedMovies.any((m) => m.tmdbId == tmdbId);
  }

  Future<void> toggleWatched(Movie movie) async {
    if (_userId == null) return;

    final currentlyWatched = isWatched(movie.tmdbId);

    // Atualiza otimisticamente a tela
    if (currentlyWatched) {
      _watchedMovies.removeWhere((m) => m.tmdbId == movie.tmdbId);
    } else {
      _watchedMovies.add(movie);
    }
    notifyListeners();

    // Envia para o Banco de Dados (Supabase)
    await repository.saveOrUpdateMovieInDb(
      movie,
      _userId!,
      isWatched: !currentlyWatched,
    );

    // Recarrega os dados reais
    loadMovies();
  }

  // ======================================================
  // AVALIAÇÃO DO USUÁRIO
  // ======================================================

  Movie? watchedMovieById(int tmdbId) {
    for (final movie in _watchedMovies) {
      if (movie.tmdbId == tmdbId) return movie;
    }
    return null;
  }

  double? userRatingFor(int tmdbId) => watchedMovieById(tmdbId)?.userRating;

  Future<bool> rateMovie(Movie movie, double rating) async {
    final userId = _userId;
    if (userId == null) return false;

    final previous = List<Movie>.of(_watchedMovies);
    final existing = watchedMovieById(movie.tmdbId);

    final rated = movie.copyWith(
      watched: true,
      userRating: rating,
      hasReview: true,
      watchedAt: existing?.watchedAt ?? DateTime.now(),
    );

    _watchedMovies = [
      ..._watchedMovies.where((m) => m.tmdbId != movie.tmdbId),
      rated,
    ];
    notifyListeners();

    try {
      await repository.saveOrUpdateMovieInDb(
        movie,
        userId,
        isWatched: true,
        userRating: rating,
      );
    } catch (error, stackTrace) {
      debugPrint('Erro ao salvar avaliação no Supabase: $error');
      debugPrint(stackTrace.toString());
      _watchedMovies = previous;
      notifyListeners();
      return false;
    }

    await _refreshWatched();
    return true;
  }

  Future<void> _refreshWatched() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      _watchedMovies = await repository.getWatchedMovies(userId);
      notifyListeners();
    } catch (error) {
      // Mantém a lista otimista em caso de erro temporário
    }
  }

  // ======================================================
  // GERENCIAMENTO DE FAVORITOS / WATCHLIST (QUERO VER)
  // ======================================================

  bool isInWatchlist(int tmdbId) {
    return _watchlistMovies.any((m) => m.tmdbId == tmdbId);
  }

  Future<void> toggleWatchlist(Movie movie) async {
    final userId = _userId;
    if (userId == null) return;

    final inList = isInWatchlist(movie.tmdbId);

    if (inList) {
      _watchlistMovies.removeWhere((m) => m.tmdbId == movie.tmdbId);
      notifyListeners();
      await repository.removeFromWatchlist(movie.tmdbId, userId);
    } else {
      _watchlistMovies.add(movie);
      notifyListeners();
      await repository.saveOrUpdateMovieInDb(
        movie,
        userId,
        isWatched: false,
      );
    }
  }

  // ======================================================
  // BUSCA DE FILMES
  // ======================================================

  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _searchResults = await repository.searchMovies(query);
    } catch (_) {
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ======================================================
  // LIMPEZA DE DADOS AO SAIR DA CONTA
  // ======================================================

  void clear() {
    _watchedMovies = [];
    _watchlistMovies = [];
    _searchResults = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getUserLists() async {
    final userId = _userId;
    if (userId == null) return [];
    return repository.getUserLists(userId);
  }

  Future<List<int>> getListIdsForMovie(int tmdbId) async {
    final userId = _userId;
    if (userId == null) return [];
    return repository.getListIdsForMovie(tmdbId, userId);
  }

  Future<List<Movie>> getMoviesFromList(int listId) async {
    return repository.getMoviesFromList(listId);
  }

  Future<void> updateMovieCustomLists(
      Movie movie, List<int> selectedListIds) async {
    final userId = _userId;
    if (userId == null) return;
    await repository.updateMovieLists(movie, userId, selectedListIds);
    notifyListeners();
  }

  Future<void> removeMovieFromCustomList(int listId, int tmdbId) async {
    await repository.removeMovieFromCustomList(listId, tmdbId);
    notifyListeners();
  }

  Future<void> deleteCustomList(int listId) async {
    await repository.deleteCustomList(listId);
    notifyListeners();
  }
}
