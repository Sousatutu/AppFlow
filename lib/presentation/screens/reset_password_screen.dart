import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../auth/auth_service.dart';

/// Inicia a recuperação de senha a partir da tela de login.
///
/// 1. Pede o e-mail e envia o código de verificação.
/// 2. Abre a [ResetPasswordScreen] para digitar o código e a nova senha.
Future<void> startPasswordRecovery(
  BuildContext context, {
  String initialEmail = '',
}) async {
  final email = await showDialog<String>(
    context: context,
    builder: (_) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );

  if (email == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ResetPasswordScreen(email: email),
    ),
  );
}

// ======================================================
// DIÁLOGO: PEDIR O E-MAIL
// ======================================================

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  Future<void> _send() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() => _error = 'Digite um e-mail válido.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.sendPasswordReset(email);

      if (!mounted) return;
      Navigator.pop(context, email);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = AuthService.friendlyError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: const Text('Recuperar senha'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enviaremos um código de verificação para o seu e-mail.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            enabled: !_loading,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              labelText: 'Seu e-mail',
              hintText: 'Digite seu e-mail',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _send,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar código'),
        ),
      ],
    );
  }
}

// ======================================================
// TELA: CÓDIGO + NOVA SENHA
// ======================================================

class ResetPasswordScreen extends StatefulWidget {
  /// E-mail que recebeu o código de verificação.
  ///
  /// Quando for `null`, a tela foi aberta por um link de recuperação (a sessão
  /// de recuperação já existe) e pede apenas a nova senha.
  final String? email;

  const ResetPasswordScreen({super.key, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _resending = false;
  bool _codeVerified = false;

  bool get _needsCode => widget.email != null;

  @override
  void initState() {
    super.initState();
    AuthService.recoveryInProgress = true;
  }

  @override
  void dispose() {
    AuthService.recoveryInProgress = false;
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _loading = true);

    try {
      // O código só pode ser usado uma vez; se a troca de senha falhar, o
      // usuário tenta de novo sem precisar de outro código.
      if (_needsCode && !_codeVerified) {
        await AuthService.verifyRecoveryCode(
          email: widget.email!,
          code: _codeController.text,
        );
        _codeVerified = true;
      }

      await AuthService.updatePassword(_passwordController.text);

      messenger.showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso!')),
      );

      // Volta para a raiz: o AuthGate já mostra o app com a sessão ativa.
      navigator.popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);
      messenger.showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(error))),
      );
    }
  }

  Future<void> _resendCode() async {
    final email = widget.email;
    if (email == null || _resending) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _resending = true);

    try {
      await AuthService.sendPasswordReset(email);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Enviamos um novo código para o seu e-mail.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.lock_reset,
                    size: 56,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Redefinir senha',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _needsCode
                        ? 'Enviamos um código para ${widget.email}. '
                            'Digite-o abaixo e escolha sua nova senha.'
                        : 'Escolha uma nova senha para a sua conta.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // CÓDIGO
                  if (_needsCode) ...[
                    _label('Código de verificação'),
                    TextFormField(
                      controller: _codeController,
                      readOnly: _codeVerified,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 14, letterSpacing: 4),
                      decoration: const InputDecoration(
                        hintText: 'Código recebido por e-mail',
                        prefixIcon: Icon(
                          Icons.pin_outlined,
                          color: AppTheme.accent,
                        ),
                      ),
                      validator: (value) {
                        if (_codeVerified) return null;

                        if (value == null || value.trim().length < 6) {
                          return 'Digite o código enviado para o seu e-mail.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // NOVA SENHA
                  _label('Nova senha'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Digite a nova senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.accent,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
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
                        return 'Informe a nova senha.';
                      }

                      if (value.length < 8) {
                        return 'A senha deve ter pelo menos 8 caracteres.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // CONFIRMAR SENHA
                  _label('Confirmar nova senha'),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Repita a nova senha',
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: AppTheme.accent,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: const Color(0xFF071018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF071018),
                              ),
                            )
                          : const Text(
                              'REDEFINIR SENHA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),

                  if (_needsCode) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: (_loading || _resending) ? null : _resendCode,
                      child: Text(
                        _resending
                            ? 'Enviando...'
                            : 'Não recebeu? Enviar novo código',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
