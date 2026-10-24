import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/app_theme.dart';
import '../../auth/auth_service.dart';
import '../../providers/movie_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _signingOut = false;

  static const List<String> _tmdbProviders = [
    'Netflix',
    'Amazon Prime Video',
    'Max',
    'Disney+',
    'Apple TV+',
    'Apple TV',
    'Globoplay',
    'Paramount+',
    'Star+',
    'Telecine',
    'Claro tv+',
    'Pluto TV',
    'Crunchyroll',
    'MUBI',
    'Lionsgate+',
    'Looke',
    'Mercado Play',
    'Google Play Movies',
    'Oldflix',
    'Reserva Imovision',
    'Belas Artes à La Carte',
  ];

  void _showServicesModal() {
    final provider = context.read<MovieProvider>();
    List<String> tempSelected = List.from(provider.userSubscriptions);
    String searchQuery = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredList = _tmdbProviders.where((service) {
              return service
                  .toLowerCase()
                  .contains(searchQuery.trim().toLowerCase());
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.stroke,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Meus Serviços Assinados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Selecione as plataformas que você assina para personalizar buscas e destaques.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) {
                        setModalState(() => searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar serviço...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.accent,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.42,
                      ),
                      child: filteredList.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text(
                                  'Nenhum serviço encontrado.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final service = filteredList[index];
                                final checked = tempSelected.contains(service);

                                return CheckboxListTile(
                                  value: checked,
                                  activeColor: AppTheme.accent,
                                  checkColor: const Color(0xFF071018),
                                  title: Text(
                                    service,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onChanged: (isVal) {
                                    setModalState(() {
                                      if (isVal == true) {
                                        tempSelected.add(service);
                                      } else {
                                        tempSelected.remove(service);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          await provider.updateUserSubscriptions(tempSelected);
                          if (modalContext.mounted) {
                            Navigator.pop(modalContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Assinaturas salvas com sucesso!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: const Color(0xFF071018),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'SALVAR ASSINATURAS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    final subscriptions = provider.userSubscriptions;
    final userRegion = provider.userRegion;

    final regionSubtitle = userRegion == 'US'
        ? 'Exibir onde passa nos Estados Unidos (US)'
        : 'Exibir onde passa no Brasil (BR)';

    final regionLabel = userRegion == 'US' ? '🇺🇸 EUA' : '🇧🇷 Brasil';

    final subtitleText = subscriptions.isEmpty
        ? 'Nenhuma selecionada'
        : '${subscriptions.length} ativa(s): ${subscriptions.join(', ')}';

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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('A sincronização está ativa na sua conta.'),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          _sectionTitle('PREFERÊNCIAS DE STREAMING'),
          const SizedBox(height: 10),

          _settingsCard(
            children: [
              _navigationTile(
                icon: Icons.live_tv_outlined,
                title: 'Meus Serviços Assinados',
                subtitle: subtitleText,
                onTap: _showServicesModal,
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
                subtitle: Text(
                  regionSubtitle,
                  style: const TextStyle(fontSize: 10),
                ),
                trailing: Text(
                  regionLabel,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () => _showRegionDialog(userRegion),
              ),
            ],
          ),

          const SizedBox(height: 22),

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
    return Material(
      color: const Color(0xFF151E29),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(
          color: Color(0xFF202D3D),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  void _showRegionDialog(String currentRegion) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Região de Catálogo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Brasil (BR)'),
                value: 'BR',
                groupValue: currentRegion,
                activeColor: AppTheme.accent,
                onChanged: (value) async {
                  if (value != null) {
                    Navigator.pop(dialogContext);
                    await context.read<MovieProvider>().updateUserRegion(value);
                  }
                },
              ),
              RadioListTile<String>(
                title: const Text('Estados Unidos (US)'),
                value: 'US',
                groupValue: currentRegion,
                activeColor: AppTheme.accent,
                onChanged: (value) async {
                  if (value != null) {
                    Navigator.pop(dialogContext);
                    await context.read<MovieProvider>().updateUserRegion(value);
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
            'Você precisará entrar novamente para acessar suas listas e avaliações.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(error))),
      );
    }
  }
}