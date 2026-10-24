import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/movie_model.dart';
import '../data/repositories/movie_repository.dart';

class MovieProvider extends ChangeNotifier {
  final MovieRepository repository;
  final _supabase = Supabase.instance.client;

  MovieProvider({required this.repository});

  List<Movie> _movies = [];
  List<Movie> _watchedMovies = [];
  List<Movie> _watchlistMovies = [];
  List<Movie> _searchResults = [];
  List<String> _userSubscriptions = ['Netflix', 'Amazon Prime Video', 'Max'];
  String _userRegion = 'BR';

  bool _isLoading = false;
  String? _errorMessage;

  List<Movie> get movies => List.unmodifiable(_movies);
  List<Movie> get watchedMovies => List.unmodifiable(_watchedMovies);
  List<Movie> get watchlistMovies => List.unmodifiable(_watchlistMovies);
  List<Movie> get searchResults => List.unmodifiable(_searchResults);
  List<String> get userSubscriptions => List.unmodifiable(_userSubscriptions);
  String get userRegion => _userRegion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<void> loadMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_userId != null) {
        final rawSubs =
            _supabase.auth.currentUser?.userMetadata?['subscriptions'];
        if (rawSubs is List) {
          _userSubscriptions = List<String>.from(rawSubs);
        }

        final rawRegion =
            _supabase.auth.currentUser?.userMetadata?['region'];
        if (rawRegion is String && rawRegion.isNotEmpty) {
          _userRegion = rawRegion;
        }

        _watchedMovies = await repository.getWatchedMovies(_userId!);
        _watchlistMovies = await repository.getWatchlistMovies(_userId!);
      }

      final popular = await repository.getTrendingMovies();

      _movies = await Future.wait(
        popular.map((movie) async {
          final full = await repository.getMovieById(
            movie.tmdbId,
            type: movie.type,
            region: _userRegion,
          );
          return full ?? movie;
        }),
      );
    } catch (e) {
      _errorMessage = 'Falha ao carregar dados: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserSubscriptions(List<String> subscriptions) async {
    _userSubscriptions = List<String>.from(subscriptions);
    notifyListeners();

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'subscriptions': _userSubscriptions},
        ),
      );
    } catch (e) {
      debugPrint('Erro ao salvar assinaturas no Supabase: $e');
    }
  }

  Future<void> updateUserRegion(String regionCode) async {
    _userRegion = regionCode;
    notifyListeners();

    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'region': _userRegion},
        ),
      );
      await loadMovies();
    } catch (e) {
      debugPrint('Erro ao salvar região no Supabase: $e');
    }
  }

  bool isWatched(int tmdbId) {
    return _watchedMovies.any((m) => m.tmdbId == tmdbId);
  }

  Future<void> toggleWatched(Movie movie) async {
    final userId = _userId;
    if (userId == null) return;

    final currentlyWatched = isWatched(movie.tmdbId);

    if (currentlyWatched) {
      _watchedMovies.removeWhere((m) => m.tmdbId == movie.tmdbId);
      notifyListeners();

      // Atualizado: em vez de removeFromWatchlist, atualiza o status de assistido para false
      // e preserva o status da watchlist.
      await repository.saveOrUpdateMovieInDb(
        movie,
        userId,
        isWatched: false,
        inWatchlist: isInWatchlist(movie.tmdbId),
      );
    } else {
      _watchedMovies.add(movie);
      notifyListeners();

      // Atualizado: salva mantendo o status independente da watchlist.
      await repository.saveOrUpdateMovieInDb(
        movie,
        userId,
        isWatched: true,
        inWatchlist: isInWatchlist(movie.tmdbId),
      );
    }

    await loadMovies();
  }

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
      // Atualizado: Envia os estados de ambas as listas
      await repository.saveOrUpdateMovieInDb(
        movie,
        userId,
        isWatched: true,
        inWatchlist: isInWatchlist(movie.tmdbId),
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
    } catch (_) {}
  }

  bool isInWatchlist(int tmdbId) {
    return _watchlistMovies.any((m) => m.tmdbId == tmdbId);
  }

  Future<bool> toggleWatchlist(Movie movie) async {
    final userId = _userId;
    if (userId == null) return false;

    final previous = List<Movie>.of(_watchlistMovies);
    final inList = isInWatchlist(movie.tmdbId);

    if (inList) {
      _watchlistMovies = _watchlistMovies.where((m) => m.tmdbId != movie.tmdbId).toList();
      notifyListeners();

      try {
        // Atualizado: em vez de remover o registro, atualizamos inWatchlist para false,
        // preservando o status de assistido.
        await repository.saveOrUpdateMovieInDb(
          movie,
          userId,
          isWatched: isWatched(movie.tmdbId),
          inWatchlist: false,
        );
      } catch (error) {
        debugPrint('Erro ao remover da watchlist no Supabase: $error');
        _watchlistMovies = previous; 
        notifyListeners();
        return false;
      }
    } else {
      _watchlistMovies = [..._watchlistMovies, movie];
      notifyListeners();

      try {
        // Atualizado: Envia os estados de ambas as listas
        await repository.saveOrUpdateMovieInDb(
          movie,
          userId,
          isWatched: isWatched(movie.tmdbId),
          inWatchlist: true,
        );
      } catch (error) {
        debugPrint('Erro ao salvar na watchlist no Supabase: $error');
        _watchlistMovies = previous; 
        notifyListeners();
        return false;
      }
    }

    await _refreshWatchlist();
    return true;
  }

  Future<void> _refreshWatchlist() async {
    final userId = _userId;
    if (userId == null) return;

    try {
      _watchlistMovies = await repository.getWatchlistMovies(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao re-buscar a watchlist: $e');
    }
  }

  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await repository.searchMovies(query);

      _searchResults = await Future.wait(
        results.map((movie) async {
          final full = await repository.getMovieById(
            movie.tmdbId,
            type: movie.type,
            region: _userRegion,
          );
          return full ?? movie;
        }),
      );
    } catch (e) {
      _errorMessage = 'Erro na busca: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _watchedMovies = [];
    _watchlistMovies = [];
    _searchResults = [];
    _userSubscriptions = ['Netflix', 'Amazon Prime Video', 'Max'];
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