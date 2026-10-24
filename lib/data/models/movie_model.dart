class Movie {
  final int? id;
  final int tmdbId;
  final String title;
  final String type;
  final String releaseDate;
  final String gender;
  final String? streaming;
  final String? posterUrl;
  final String? synopsis;
  final double criticRating;
  final int duration;
  final bool watched;
  final double? userRating;
  final String? status;
  final bool hasReview;
  final DateTime? watchedAt;
  final List<String> watchProviders;
  final String? directorName; // Nome do Diretor

  Movie({
    this.id,
    required this.tmdbId,
    required this.title,
    this.type = 'Filme',
    this.releaseDate = '',
    required this.gender,
    this.streaming,
    this.posterUrl,
    this.synopsis,
    required this.criticRating,
    this.duration = 0, // Alterado para 0 como padrão
    this.watched = false,
    this.userRating,
    this.status,
    this.hasReview = false,
    this.watchedAt,
    this.watchProviders = const [],
    this.directorName,
  });

  Movie copyWith({
    int? id,
    int? tmdbId,
    String? title,
    String? type,
    String? releaseDate,
    String? gender,
    String? streaming,
    String? posterUrl,
    String? synopsis,
    double? criticRating,
    int? duration,
    bool? watched,
    double? userRating,
    String? status,
    bool? hasReview,
    DateTime? watchedAt,
    List<String>? watchProviders,
    String? directorName,
  }) {
    return Movie(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      type: type ?? this.type,
      releaseDate: releaseDate ?? this.releaseDate,
      gender: gender ?? this.gender,
      streaming: streaming ?? this.streaming,
      posterUrl: posterUrl ?? this.posterUrl,
      synopsis: synopsis ?? this.synopsis,
      criticRating: criticRating ?? this.criticRating,
      duration: duration ?? this.duration,
      watched: watched ?? this.watched,
      userRating: userRating ?? this.userRating,
      status: status ?? this.status,
      hasReview: hasReview ?? this.hasReview,
      watchedAt: watchedAt ?? this.watchedAt,
      watchProviders: watchProviders ?? this.watchProviders,
      directorName: directorName ?? this.directorName,
    );
  }

  String get year =>
      releaseDate.isNotEmpty ? releaseDate.split('-').first : 'N/A';

  // Exibe a duração real se disponível, caso contrário 'N/A'
  String get runtime => duration > 0 ? '$duration min' : 'N/A';

  List<String> get genres => [gender.isNotEmpty ? gender : type];

  double get rating => criticRating > 0 ? criticRating / 2 : 0.0;

  String get streamingProvider => watchProviders.isNotEmpty
      ? watchProviders.join(', ')
      : (streaming ?? 'Indisponível');

  String get director => directorName ?? 'Indisponível';

  factory Movie.fromTmdbJson(Map<String, dynamic> json,
      {String? defaultDirector}) {
    // 1. Identifica se é Filme ou Série
    String mediaType = 'Filme';
    if (json['media_type'] == 'tv' ||
        (json.containsKey('name') && !json.containsKey('title')) ||
        json.containsKey('first_air_date')) {
      mediaType = 'Série';
    }

    // 2. Extrai o Gênero principal
    String mainGender = '';
    if (json['genres'] != null && (json['genres'] as List).isNotEmpty) {
      mainGender = json['genres'][0]['name'] ?? '';
    }

    // 3. Extrai o Diretor da equipe de produção (Crew)
    String? foundDirector = defaultDirector;
    if (json['credits'] != null && json['credits']['crew'] != null) {
      final crew = json['credits']['crew'] as List;
      final directorObj = crew.firstWhere(
        (member) =>
            member['job'] == 'Director' ||
            member['known_for_department'] == 'Directing',
        orElse: () => null,
      );
      if (directorObj != null) {
        foundDirector = directorObj['name'];
      }
    }

    // 4. Extrai Provedores de Streaming no Brasil
    List<String> providersList = [];
    final brData = json['watch/providers']?['results']?['BR'];
    if (brData != null) {
      final flatrate = brData['flatrate'] as List?;
      if (flatrate != null) {
        for (var item in flatrate) {
          if (item['provider_name'] != null) {
            providersList.add(item['provider_name'] as String);
          }
        }
      }
    }

    // 5. Extrai Duração real (runtime para filmes / episode_run_time para séries)
    int movieDuration = 0;
    if (json['runtime'] != null && json['runtime'] > 0) {
      movieDuration = json['runtime'];
    } else if (json['episode_run_time'] != null &&
        (json['episode_run_time'] as List).isNotEmpty) {
      movieDuration = json['episode_run_time'][0];
    }

    return Movie(
      tmdbId: json['id'] ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      type: mediaType,
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      gender: mainGender,
      posterUrl: json['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : null,
      synopsis: json['overview'],
      criticRating: (json['vote_average'] ?? 0.0).toDouble(),
      duration: movieDuration,
      watchProviders: providersList,
      directorName: foundDirector,
    );
  }

  factory Movie.fromSupabase(Map<String, dynamic> json) {
  return Movie(
    id: json['id'] as int?,
    tmdbId: (json['tmdb_id'] ?? 0) as int,
    title: json['title'] as String? ?? '',
    type: json['type'] as String? ?? 'Filme',
    releaseDate: json['release_date'] as String? ?? '',
    gender: json['gender'] as String? ?? '',
    streaming: json['streaming'] as String?,
    posterUrl: json['poster_url'] as String?,
    synopsis: json['synopsis'] as String?,
    criticRating: (json['critic_rating'] as num?)?.toDouble() ?? 0.0,
    duration: (json['duration'] as num?)?.toInt() ?? 0,
    watched: json['watched'] as bool? ?? false,
    userRating: (json['user_rating'] as num?)?.toDouble(),
    status: json['status'] as String?,
    hasReview: json['user_rating'] != null,
    watchedAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null,
  );
}
}
