import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode;

/// Concentra as operações de autenticação do Enic.
///
/// As telas chamam este serviço em vez de falar direto com o Supabase, o que
/// mantém os fluxos (login social, recuperação de senha e logout) em um só
/// lugar. A navegação depois do login/logout é feita pelo [AuthGate].
class AuthService {
  AuthService._();

  /// Deep link usado para voltar ao app depois do login social.
  ///
  /// Precisa ser o mesmo valor cadastrado em:
  /// - Supabase > Authentication > URL Configuration > Redirect URLs
  /// - AndroidManifest.xml (intent-filter)
  /// - ios/Runner/Info.plist (CFBundleURLSchemes)
  static const String redirectUrl = 'io.supabase.appflow://login-callback/';

  /// Fica `true` enquanto o usuário redefine a senha. Impede que o AuthGate
  /// feche a tela de "nova senha" quando a sessão de recuperação é criada.
  static bool recoveryInProgress = false;

  static GoTrueClient get _auth => Supabase.instance.client.auth;

  // ---------------------------------------------------------------------------
  // LOGIN SOCIAL
  // ---------------------------------------------------------------------------

  static Future<void> signInWithGoogle() {
    return _signInWithProvider(OAuthProvider.google);
  }

  static Future<void> _signInWithProvider(OAuthProvider provider) async {
    final opened = await _auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : redirectUrl,
      // O Google bloqueia login dentro de WebView embutida; por isso o
      // navegador externo no mobile.
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );

    if (!opened) {
      throw const AuthException('Não foi possível abrir a página de login.');
    }
  }

  // ---------------------------------------------------------------------------
  // RECUPERAÇÃO DE SENHA
  // ---------------------------------------------------------------------------

  /// Envia o e-mail de recuperação (código de verificação / link).
  static Future<void> sendPasswordReset(String email) {
    return _auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: kIsWeb ? null : redirectUrl,
    );
  }

  /// Confere o código recebido por e-mail e abre uma sessão de recuperação.
  static Future<void> verifyRecoveryCode({
    required String email,
    required String code,
  }) async {
    await _auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
  }

  /// Define a nova senha do usuário (exige sessão ativa/de recuperação).
  static Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  // ---------------------------------------------------------------------------
  // SAIR DA CONTA
  // ---------------------------------------------------------------------------

  static Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // MENSAGENS DE ERRO EM PORTUGUÊS
  // ---------------------------------------------------------------------------

  static String friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();

      if (message.contains('invalid login credentials')) {
        return 'E-mail ou senha incorretos.';
      }

      if (message.contains('email not confirmed')) {
        return 'Confirme seu e-mail antes de entrar.';
      }

      if (message.contains('rate limit') ||
          message.contains('security purposes') ||
          error.statusCode == '429') {
        return 'Muitas tentativas. Aguarde um minuto e tente novamente.';
      }

      if (message.contains('token') ||
          message.contains('otp') ||
          message.contains('expired')) {
        return 'Código inválido ou expirado. Solicite um novo código.';
      }

      if (message.contains('different from the old password')) {
        return 'A nova senha precisa ser diferente da senha atual.';
      }

      if (message.contains('password')) {
        return 'Escolha uma senha mais forte, com pelo menos 8 caracteres.';
      }

      return error.message;
    }

    return 'Algo deu errado. Verifique sua conexão e tente novamente.';
  }
}
