import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import '../providers/movie_provider.dart';
import '../presentation/main_nav_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/reset_password_screen.dart';

/// Porta de entrada do app.
///
/// Mostra a [MainNavScreen] quando há sessão ativa e a [LoginScreen] quando
/// não há. Como escuta o Supabase, ele cuida sozinho de:
/// - login por e-mail/senha e login social (Google/Apple);
/// - sessão salva de uma abertura anterior do app;
/// - "Sair da conta" (volta para o login de qualquer tela);
/// - link de recuperação de senha aberto no aparelho.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  String? _userId;

  @override
  void initState() {
    super.initState();

    final auth = Supabase.instance.client.auth;
    _userId = auth.currentUser?.id;
    _subscription = auth.onAuthStateChange.listen(_onAuthChange);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    if (!mounted) return;

    // Link de recuperação aberto pelo e-mail: pede a nova senha.
    if (state.event == AuthChangeEvent.passwordRecovery &&
        !AuthService.recoveryInProgress) {
      AuthService.recoveryInProgress = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordScreen(),
          ),
        );
      });
    }

    final newUserId = state.session?.user.id;
    if (newUserId == _userId) return;

    // Trocou o usuário (entrou ou saiu): sincroniza os dados do app.
    final movies = context.read<MovieProvider>();
    if (newUserId == null) {
      movies.clear();
    } else {
      movies.loadMovies();
    }

    // Fecha telas empilhadas (Cadastro, Configurações, diálogos...), exceto
    // durante a redefinição de senha.
    if (!AuthService.recoveryInProgress) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    setState(() => _userId = newUserId);
  }

  @override
  Widget build(BuildContext context) {
    return _userId == null ? const LoginScreen() : const MainNavScreen();
  }
}
