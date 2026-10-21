import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_service.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: '',
  );
  final _passwordController = TextEditingController(
    text: '',
  );

  bool _obscurePassword = true;
  bool _isLogin = true;
  bool _socialLoading = false;

  // A função de navegação fica aqui.
  void _openRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // A navegação para o app é automática: o AuthGate (main.dart) detecta
        // a nova sessão e exibe a MainNavScreen.
      } else {
        _openRegisterScreen();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro no Login: ${e.message}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro inesperado: $error')),
        );
      }
    }
  }

  void _forgotPassword() {
    startPasswordRecovery(
      context,
      initialEmail: _emailController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF111B28),
              Color(0xFF090D14),
              Color(0xFF05070B),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 42,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),

                        // LOGOTIPO
                        Center(
                          child: Container(
                            width: 260,
                            height: 220,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Color(0xFF112A39),
                                  Color(0xFF101B28),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const _EnicLogo(),
                                const SizedBox(height: 4),
                                RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1.3,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'ENIC',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Seu catálogo inteligente de filmes e séries',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ALTERNAR LOGIN E CADASTRO
                        Container(
                          height: 46,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _AuthTabButton(
                                  label: 'ENTRAR',
                                  selected: _isLogin,
                                  onTap: () {
                                    setState(() => _isLogin = true);
                                  },
                                ),
                              ),
                              Expanded(
                                child: _AuthTabButton(
                                  label: 'CRIAR CONTA',
                                  selected: false,
                                  onTap: _openRegisterScreen,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // E-MAIL
                        const Text(
                          'E-mail',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Digite seu e-mail',
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe seu e-mail.';
                            }

                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Digite um e-mail válido.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // SENHA
                        const Text(
                          'Senha',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 7),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Digite sua senha',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              color: AppTheme.accent,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Informe sua senha.';
                            }

                            if (value.length < 8) {
                              return 'A senha deve ter pelo menos 8 caracteres.';
                            }

                            return null;
                          },
                        ),

                        if (_isLogin) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              child: const Text(
                                'Esqueceu a senha?',
                                style: TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 6),

                        // BOTÃO PRINCIPAL
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: _submitForm,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: const Color(0xFF071018),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'ENTRAR NO ENIC' : 'CRIAR MINHA CONTA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // DIVISOR
                        const Row(
                          children: [
                            Expanded(
                              child: Divider(color: AppTheme.stroke),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'ou continue com',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppTheme.stroke),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // LOGIN SOCIAL
                        Row(children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Google',
                              icon: const Text(
                                'G',
                                style: TextStyle(
                                  color: Color(0xFF4285F4),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              onTap: () =>
                                  _socialSignIn(AuthService.signInWithGoogle),
                            ),
                          ),
                        ]),

                        const SizedBox(height: 22),

                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock,
                              size: 11,
                              color: AppTheme.starGold,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Autenticação segura via Supabase Auth',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Login social (Google/Apple) via OAuth do Supabase. Ao voltar para o app, o
  // AuthGate detecta a sessão e abre a MainNavScreen.
  Future<void> _socialSignIn(Future<void> Function() signIn) async {
    if (_socialLoading) return;
    setState(() => _socialLoading = true);

    try {
      await signIn();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _socialLoading = false);
    }
  }
}

// LOGOTIPO CIRCULAR
class _EnicLogo extends StatelessWidget {
  const _EnicLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accent,
                width: 2.5,
              ),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.accent,
                width: 2,
              ),
            ),
          ),
          const Icon(
            Icons.circle,
            size: 9,
            color: AppTheme.accent,
          ),
          const Positioned(
            top: 9,
            child: Icon(
              Icons.circle,
              size: 7,
              color: AppTheme.accent,
            ),
          ),
          const Positioned(
            bottom: 9,
            child: Icon(
              Icons.circle,
              size: 7,
              color: AppTheme.accent,
            ),
          ),
          const Positioned(
            left: 9,
            child: Icon(
              Icons.circle,
              size: 7,
              color: AppTheme.accent,
            ),
          ),
          const Positioned(
            right: 9,
            child: Icon(
              Icons.circle,
              size: 7,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// BOTÕES ENTRAR / CRIAR CONTA
class _AuthTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF071018) : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// BOTÕES SOCIAIS
class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppTheme.surface,
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppTheme.stroke),
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
