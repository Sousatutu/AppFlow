import '../models/movie_model.dart';

abstract class MovieRepository {
  Future<List<Movie>> getTrendingMovies();
  Future<List<Movie>> getWatchedMovies(String userId);
  Future<List<Movie>> getWatchlistMovies(String userId);
  Future<List<Movie>> searchMovies(String query);
  Future<Movie?> getMovieById(
    int tmdbId, 
    {
      String type = 'Filme',
      String region = 'BR',
    });
  Future<void> saveOrUpdateMovieInDb(
    Movie movie, 
    String userId, {
    required bool isWatched,
    required bool inWatchlist,
    double? userRating,
  });
  Future<void> removeFromWatchlist(int tmdbId, String userId);
  Future<List<Map<String, dynamic>>> getUserLists(String userId);
  Future<List<int>> getListIdsForMovie(int tmdbId, String userId);
  Future<List<Movie>> getMoviesFromList(int listId);
  Future<void> updateMovieLists(
      Movie movie, String userId, List<int> selectedListIds);
  Future<void> removeMovieFromCustomList(int listId, int tmdbId);
  Future<void> deleteCustomList(int listId);
}
