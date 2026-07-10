import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final String userId; // Recebe o UID do usuário vindo da Home

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      // O StreamBuilder escuta o banco em tempo real. Se o nome/saldo mudar, a tela atualiza sozinha.
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          // Exibe indicador de carregamento enquanto conecta ao banco
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5BBF4E)),
              ),
            );
          }

          // Caso ocorra algum erro ou o usuário não exista no banco
          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao carregar dados do usuário ou registro não encontrado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }

          // Recupera os dados convertendo em um Map do Firestore
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          // Extração das variáveis vindas da sua estrutura de registro
          final String nome = userData['nome'] ?? 'Usuário';
          final String email = userData['email'] ?? 'Sem e-mail';
          final String cpfRaw = userData['cpf'] ?? '00000000000';
          final double saldo = (userData['saldo'] as num?)?.toDouble() ?? 0.0;
          final String imagemPerfil = userData['imagem_perfil'] ?? '';

          // Formatação simples para o CPF (Ex: 000.000.000-00)
          String cpfFormatado = cpfRaw;
          if (cpfRaw.length == 11) {
            cpfFormatado =
                '${cpfRaw.substring(0, 3)}.${cpfRaw.substring(3, 6)}.${cpfRaw.substring(6, 9)}-${cpfRaw.substring(9)}';
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Section dinâmico com dados reais do Firestore
                  _ProfileHeader(
                    nome: nome,
                    saldo: saldo,
                    imagemUrl: imagemPerfil,
                  ),
                  const SizedBox(height: 28),

                  // Personal Info Section
                  Text(
                    'Informações pessoais',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoCard(
                    infoRows: [
                      {
                        'icon': Icons.badge_outlined,
                        'label': 'CPF',
                        'value': cpfFormatado,
                      },
                      {
                        'icon': Icons.email_outlined,
                        'label': 'E-mail',
                        'value': email,
                      },
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Account/Preferences Section
                  Text(
                    'Conta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AccountPreferencesCard(context: context),
                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(context),
                  const SizedBox(height: 32),

                  // App Version Footer
                  Center(
                    child: Text(
                      'PagBus v1.0.0',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF5BBF4E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Meu Perfil',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Edição em breve'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmationDialog(context),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout, color: Color(0xFFE53935), size: 20),
        label: const Text(
          'Sair da conta',
          style: TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text('Deseja realmente desconectar do aplicativo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // fecha o dialog
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // fecha o dialog

              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile header configurado com dados dinâmicos do Firestore
class _ProfileHeader extends StatelessWidget {
  final String nome;
  final double saldo;
  final String imagemUrl;

  const _ProfileHeader({
    Key? key,
    required this.nome,
    required this.saldo,
    required this.imagemUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Utiliza a URL do avatar guardada no Firestore ou um ícone caso falhe
              CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: imagemUrl.isNotEmpty
                    ? NetworkImage(imagemUrl)
                    : null,
                child: imagemUrl.isEmpty
                    ? const Icon(Icons.person, size: 56, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Upload de foto em breve'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Color(0xFF5BBF4E),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            nome,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Saldo: R\$ ${saldo.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable info card configurado de forma limpa
class _InfoCard extends StatelessWidget {
  final List<Map<String, dynamic>> infoRows;

  const _InfoCard({Key? key, required this.infoRows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: infoRows.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[300],
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final row = infoRows[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  row['icon'] as IconData,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['label'] as String,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        row['value'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Card de configurações estáticas
class _AccountPreferencesCard extends StatelessWidget {
  final BuildContext context;

  const _AccountPreferencesCard({Key? key, required this.context})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accountOptions = [
      {'icon': Icons.lock_outline, 'title': 'Alterar senha'},
      {'icon': Icons.notifications_none, 'title': 'Notificações'},
      {'icon': Icons.help_outline, 'title': 'Ajuda e suporte'},
      {'icon': Icons.description_outlined, 'title': 'Termos e privacidade'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: accountOptions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[300],
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final option = accountOptions[index];
          return InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${option['title']} em breve'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    option['icon'] as IconData,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      option['title'] as String,
                      style: TextStyle(fontSize: 14, color: Colors.grey[900]),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
