import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  String get _password => _passwordController.text;

  bool get _hasMinLength => _password.length >= 8;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Valida o formulário e prepara o cadastro para integração com a API.
  void _finishRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os Termos para continuar.')),
      );
      return;
    }

    try {
      // CRIA A CONTA NO SUPABASE
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim()
        }, // Campo customizado de nome
      );

      if (!mounted) return;

      // Sem confirmação de e-mail, o Supabase já devolve uma sessão e o
      // AuthGate (main.dart) leva o usuário direto para o app.
      if (response.session != null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Conta criada! Confirme seu e-mail para poder entrar.',
          ),
        ),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar: ${e.message}')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $error')),
      );
    }
  }

  // Exibe o conteúdo provisório dos documentos.
  void _showTerms(String title) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Text(title),
          content: const Text(
            'O conteúdo definitivo deste documento deverá ser '
            'fornecido pelo responsável pelo projeto.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Cadastro/entrada com Google via OAuth do Supabase. Ao voltar para o app, o
  // AuthGate detecta a sessão e abre a MainNavScreen.
  Future<void> _googleRegistration() async {
    try {
      await AuthService.signInWithGoogle();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(error))),
      );
    }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // CABEÇALHO
                  Row(
                    children: [
                      _BackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Crie sua Conta',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Organize seus filmes e descubra onde assistir',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // CADASTRO COM GOOGLE
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _googleRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF17202E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              color: Color(0xFF4285F4),
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 24),
                          Text(
                            'Cadastre-se com o Google',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // DIVISOR
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: AppTheme.stroke),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'ou com seu e-mail',
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

                  const SizedBox(height: 16),

                  // NOME COMPLETO
                  const _FieldLabel('Nome Completo'),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Seu nome completo',
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu nome completo.';
                      }

                      if (value.trim().split(RegExp(r'\s+')).length < 2) {
                        return 'Informe nome e sobrenome.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // E-MAIL
                  const _FieldLabel('E-mail'),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'seu@email.com',
                      prefixIcon: Icon(
                        Icons.mail_outline,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu e-mail.';
                      }

                      final emailRegex = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      );

                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Digite um e-mail válido.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 10),

                  // SENHA
                  const _FieldLabel('Senha'),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'Crie uma senha',
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
                        return 'Crie uma senha.';
                      }

                      if (value.length < 8) {
                        return 'A senha deve ter pelo menos 8 caracteres.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 7),

                  // INDICADOR DE COMPRIMENTO DA SENHA
                  Row(
                    children: [
                      _StrengthBar(active: _hasMinLength),
                      const SizedBox(width: 6),
                      _StrengthBar(active: _hasMinLength),
                      const SizedBox(width: 6),
                      _StrengthBar(active: _hasMinLength),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _hasMinLength
                        ? 'Senha válida: 8 caracteres ou mais'
                        : 'A senha deve ter pelo menos 8 caracteres',
                    style: TextStyle(
                      color: _hasMinLength
                          ? const Color(0xFF00D68F)
                          : AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // CONFIRMAR SENHA
                  const _FieldLabel('Confirmar Senha'),

                  const SizedBox(height: 6),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Repita sua senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme sua senha.';
                      }

                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  // ACEITE DOS TERMOS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 25,
                        height: 30,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                          activeColor: AppTheme.accent,
                          checkColor: const Color(0xFF071018),
                          side: const BorderSide(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Li e concordo com os ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showTerms('Termos de Uso'),
                        child: const Text(
                          'Termos',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Text(
                        ' e ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showTerms('Política de Privacidade'),
                        child: const Text(
                          'Privacidade',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // FINALIZAR CADASTRO
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _finishRegistration,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF071018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'FINALIZAR CADASTRO',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // VOLTAR AO LOGIN
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      const Text(
                        'Já tem uma conta no Enic? ',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

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
                          'Cadastro integrado com Supabase Auth & Google Cloud',
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
        ),
      ),
    );
  }
}

// RÓTULOS DOS CAMPOS
class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }
}

// INDICADORES DO COMPRIMENTO DA SENHA
class _StrengthBar extends StatelessWidget {
  final bool active;

  const _StrengthBar({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00D68F) : AppTheme.stroke,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

// BOTÃO DE VOLTAR
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.stroke,
          ),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 17,
          color: Colors.white,
        ),
      ),
    );
  }
}
