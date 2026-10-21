import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _region = 'Brasil';
  String _services = 'Netflix, Max, Prime Video';
  bool _signingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurações',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // CONTA E SEGURANÇA
          _sectionTitle('CONTA & SEGURANÇA'),
          const SizedBox(height: 10),

          _settingsCard(
            children: [
              SwitchListTile(
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppTheme.accent,
                ),
                title: const Text(
                  'Alertas de Lançamento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Avisar quando filmes da lista estrearem',
                  style: TextStyle(fontSize: 10),
                ),
                value: _notifications,
                activeTrackColor: AppTheme.accent,
                onChanged: (value) {
                  setState(() => _notifications = value);
                },
              ),
              _divider(),
              ListTile(
                leading: const Icon(
                  Icons.cloud_sync_outlined,
                  color: AppTheme.accent,
                ),
                title: const Text(
                  'Sincronização na Nuvem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Text(
                  'Ativa',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  _showMessage(
                    'A sincronização está ativa na sua conta.',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // PREFERÊNCIAS DE STREAMING
          _sectionTitle('PREFERÊNCIAS DE STREAMING'),
          const SizedBox(height: 10),

          _settingsCard(
            children: [
              _navigationTile(
                icon: Icons.live_tv_outlined,
                title: 'Meus Serviços Assinados',
                subtitle: 'Netflix, Max, Prime Video (3 ativos)',
                onTap: _showServicesDialog,
              ),
              _divider(),
              ListTile(
                leading: const Icon(
                  Icons.public,
                  color: AppTheme.accent,
                ),
                title: const Text(
                  'Região de Catálogo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Exibir onde passa no Brasil (BR)',
                  style: TextStyle(fontSize: 10),
                ),
                trailing: Text(
                  _region == 'Brasil' ? '🇧🇷 Brasil' : '🇺🇸 EUA',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _showRegionDialog,
              ),
            ],
          ),

          const SizedBox(height: 22),

          // APLICATIVO
          _sectionTitle('APLICATIVO'),
          const SizedBox(height: 10),

          _settingsCard(
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final versionText = snapshot.hasData
                      ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                      : 'Carregando...';

                  return ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppTheme.accent,
                    ),
                    title: const Text(
                      'Versão do Enic',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Text(
                      versionText,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // SAIR DA CONTA
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _signingOut ? null : _confirmSignOut,
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'SAIR DA CONTA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF4545),
                side: const BorderSide(
                  color: Color(0xFFFF4545),
                ),
                backgroundColor: const Color(0xFF350D10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Desenvolvido com Flutter · Powered by TMDB & Supabase',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151E29),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF202D3D),
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF202D3D),
      indent: 14,
      endIndent: 14,
    );
  }

  Widget _navigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.accent,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 10,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showServicesDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Meus Serviços Assinados'),
          content: TextField(
            controller: TextEditingController(text: _services),
            decoration: const InputDecoration(
              hintText: 'Netflix, Max, Prime Video',
              labelText: 'Serviços',
            ),
            onChanged: (value) {
              _services = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(dialogContext);
                _showMessage(
                  'Preferência atualizada nesta sessão.',
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  void _showRegionDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Região de Catálogo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Brasil'),
                value: 'Brasil',
                groupValue: _region,
                activeColor: AppTheme.accent,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _region = value;
                    });
                    Navigator.pop(dialogContext);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Estados Unidos'),
                value: 'EUA',
                groupValue: _region,
                activeColor: AppTheme.accent,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _region = value;
                    });
                    Navigator.pop(dialogContext);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta?'),
          content: const Text(
            'Você precisará entrar novamente para acessar suas listas '
            'e avaliações.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _signOut();
              },
              child: const Text(
                'Sair',
                style: TextStyle(color: Color(0xFFFF4545)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);

    try {
      await AuthService.signOut();
    } catch (error) {
      if (!mounted) return;

      setState(() => _signingOut = false);
      _showMessage(AuthService.friendlyError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
