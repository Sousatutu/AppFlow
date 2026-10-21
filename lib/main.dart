import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/repositories/api_movie_repository.dart';
import 'providers/movie_provider.dart';
import 'auth/auth_gate.dart';

// Variável global para acesso rápido
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    ChangeNotifierProvider<MovieProvider>(
      create: (_) => MovieProvider(
        repository: ApiMovieRepository(),
      )..loadMovies(),
      child: const EnicApp(),
    ),
  );
}

class EnicApp extends StatelessWidget {
  const EnicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}
