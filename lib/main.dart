import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'catalogo.dart'; // Importando a tela do catálogo que vamos criar

void main() async {
  // Inicializa o Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega o arquivo .env
  await dotenv.load(fileName: ".env");

  // Inicializa o Supabase pegando as chaves do .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Catalogo(),
  ));
}

// Instância global do cliente Supabase para acessar em qualquer lugar
final supabase = Supabase.instance.client;
