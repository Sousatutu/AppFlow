import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movie_model.dart';
import 'movie_repository.dart';

class ApiMovieRepository implements MovieRepository {
  final String _baseUrl = 'https://api.themoviedb.org/3';
  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';
  final _supabase = Supabase.instance.client;

  @override
  Future<List<Movie>> getTrendingMovies() async {
    final url = Uri.parse(
        '$_baseUrl/trending/all/week?language=pt-BR&api_key=$_apiKey');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      return results
          .where((item) =>
              item['media_type'] == 'movie' || item['media_type'] == 'tv')
          .map((json) => Movie.fromTmdbJson(json))
          .toList();
    } else {
      throw Exception('Falha ao carregar tendências do TMDB');
    }
  }

  @override
  Future<List<Movie>> getWatchedMovies(String userId) async {
    final data = await _supabase
        .from('movies')
        .select()
        .eq('user_id', userId)
        .eq('watched', true);

    return (data as List).map((item) => Movie.fromSupabase(item)).toList();
  }

  @override
  Future<Movie?> getMovieById(int tmdbId, {String type = 'Filme', String region = 'BR'}) async {
    final isTv = type.toLowerCase() == 'série' ||
        type.toLowerCase() == 'serie' ||
        type.toLowerCase() == 'tv';

    final primaryEndpoint = isTv ? 'tv' : 'movie';
    final secondaryEndpoint = isTv ? 'movie' : 'tv';

    // 1. Tenta buscar no endpoint correto primeiro (tv ou movie)
    final primaryUrl = Uri.parse(
      '$_baseUrl/$primaryEndpoint/$tmdbId?language=pt-BR&api_key=$_apiKey&append_to_response=watch/providers,credits',
    );
    var response = await http.get(primaryUrl);

    if (response.statusCode == 200) {
      return Movie.fromTmdbJson(json.decode(response.body));
    }

    // 2. Se falhar, tenta o endpoint secundário como fallback
    final secondaryUrl = Uri.parse(
      '$_baseUrl/$secondaryEndpoint/$tmdbId?language=pt-BR&api_key=$_apiKey&append_to_response=watch/providers,credits',
    );
    response = await http.get(secondaryUrl);

    if (response.statusCode == 200) {
      return Movie.fromTmdbJson(json.decode(response.body));
    }

    return null;
  }

  @override
  Future<void> saveOrUpdateMovieInDb(
    Movie movie, 
    String userId, {
    required bool isWatched,
    required bool inWatchlist, 
    double? userRating,

    }) async {
    Movie fullMovie = movie;

    if (movie.watchProviders.isEmpty ||
        movie.duration == 0 ||
        movie.releaseDate.isEmpty) {
      try {
        final details = await getMovieById(movie.tmdbId, type: movie.type);
        if (details != null) {
          fullMovie = details.copyWith(
            id: movie.id,
            watched: isWatched,
            userRating: userRating ?? movie.userRating,
          );
        }
      } catch (e) {
        // Se a API do TMDB falhar, prossegue com o salvamento dos dados atuais do filme
      }
    }

    final existing = await _supabase
        .from('movies')
        .select('id')
        .eq('user_id', userId)
        .eq('tmdb_id', movie.tmdbId)
        .maybeSingle();

    final movieData = {
      'tmdb_id': fullMovie.tmdbId,
      'title': fullMovie.title,
      'type': fullMovie.type,
      'release_date': fullMovie.releaseDate,
      'gender': fullMovie.genres.first,
      'streaming': fullMovie.streamingProvider,
      'poster_url': fullMovie.posterUrl,
      'synopsis': fullMovie.synopsis,
      'critic_rating': fullMovie.criticRating,
      'duration': fullMovie.duration,
      'watched': isWatched,
      'in_watchlist': inWatchlist,
      if (userRating != null) 'user_rating': userRating,
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (existing != null) {
      await _supabase.from('movies').update(movieData).eq('id', existing['id']);
    } else {
      await _supabase.from('movies').insert(movieData);
    }
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl/search/multi?query=${Uri.encodeComponent(query)}&language=pt-BR&api_key=$_apiKey',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'] ?? [];
      final List<Movie> moviesList = [];

      for (var item in results) {
        final mediaType = item['media_type'];

        if (mediaType == 'movie' || mediaType == 'tv') {
          moviesList.add(Movie.fromTmdbJson(item));
        } 
        else if (mediaType == 'person') {
          final int personId = item['id'];
          final String personName = item['name'] ?? '';

          final creditsUrl = Uri.parse(
            '$_baseUrl/person/$personId/combined_credits?language=pt-BR&api_key=$_apiKey'
          );
          final creditsResponse = await http.get(creditsUrl);

          if (creditsResponse.statusCode == 200) {
            final creditsData = json.decode(creditsResponse.body);
            final crewList = creditsData['crew'] as List;

            final directedWorks = crewList.where((m) => m['job'] == 'Director').toList();

            for (var work in directedWorks) {
              moviesList.add(Movie.fromTmdbJson(work, defaultDirector: personName));
            }
          }
        }
      }
      return moviesList;
    }
    return [];
  }

  @override
  Future<List<Movie>> getWatchlistMovies(String userId) async {
    final data = await _supabase
        .from('movies')
        .select()
        .eq('user_id', userId)
        .eq('in_watchlist', true);

    return (data as List).map((item) => Movie.fromSupabase(item)).toList();
  }

  @override
  Future<void> removeFromWatchlist(int tmdbId, String userId) async {
    await _supabase
        .from('movies')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId);
  }

  @override
  Future<List<Map<String, dynamic>>> getUserLists(String userId) async {
    final response = await _supabase
        .from('lists')
        .select('id, name')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<int>> getListIdsForMovie(int tmdbId, String userId) async {
    final response = await _supabase
        .from('list_movies')
        .select('list_id')
        .eq('user_id', userId)
        .eq('tmdb_id', tmdbId);

    return (response as List)
        .map<int>((item) => item['list_id'] as int)
        .toList();
  }

  @override
  Future<List<Movie>> getMoviesFromList(int listId) async {
    final response =
        await _supabase.from('list_movies').select().eq('list_id', listId);

    return (response as List).map((item) {
      return Movie(
        tmdbId: item['tmdb_id'],
        title: item['title'] ?? '',
        gender: item['gender'] ?? '',
        posterUrl: item['poster_url'],
        releaseDate: item['release_date'] ?? '',
        criticRating: (item['critic_rating'] ?? 0.0).toDouble(),
      );
    }).toList();
  }

  @override
  Future<void> updateMovieLists(
      Movie movie, String userId, List<int> selectedListIds) async {
    await _supabase
        .from('list_movies')
        .delete()
        .eq('user_id', userId)
        .eq('tmdb_id', movie.tmdbId);

    if (selectedListIds.isNotEmpty) {
      final String genreText =
          movie.genres.isNotEmpty ? movie.genres.first : 'Filme';

      final rowsToInsert = selectedListIds.map((listId) {
        return {
          'list_id': listId,
          'tmdb_id': movie.tmdbId,
          'title': movie.title,
          'gender': genreText,
          'poster_url': movie.posterUrl,
          'release_date': movie.releaseDate,
          'critic_rating': movie.criticRating,
          'user_id': userId,
        };
      }).toList();

      await _supabase.from('list_movies').insert(rowsToInsert);
    }
  }

  @override
  Future<void> removeMovieFromCustomList(int listId, int tmdbId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('list_movies')
        .delete()
        .eq('list_id', listId)
        .eq('tmdb_id', tmdbId)
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteCustomList(int listId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('list_movies')
        .delete()
        .eq('list_id', listId)
        .eq('user_id', userId);

    await _supabase
        .from('lists')
        .delete()
        .eq('id', listId)
        .eq('user_id', userId);
  }
}
