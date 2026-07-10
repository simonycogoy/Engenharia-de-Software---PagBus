import 'package:flutter/material.dart';
import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'qr_code_full_screen.dart';
import 'recharge_screen.dart';
import 'profile_screen.dart';
import 'schedules_screen.dart';
import 'expenses_screen.dart';
import 'notifications_center_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const HomeScreen({Key? key, required this.userId, required this.userName})
    : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variável para controlar o filtro selecionado no menu dropdown
  String _filtroSelecionado = 'Recentes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _BalanceCard(userId: widget.userId, defaultName: widget.userName),
            const SizedBox(height: 16),
            _buildFilterRow(),
            const SizedBox(height: 16),
            _buildTransactionList(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4CAF50),
        shape: const CircleBorder(),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RechargeScreen(userId: widget.userId),
            ),
          );
          if (mounted) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(userId: widget.userId),
              ),
            );
          },
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              String imagemPerfil = '';

              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                imagemPerfil = data['imagem_perfil'] ?? '';
              }

              return CircleAvatar(
                backgroundColor: Colors.grey,
                backgroundImage: imagemPerfil.isNotEmpty
                    ? NetworkImage(imagemPerfil)
                    : null,
                child: imagemPerfil.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              );
            },
          ),
        ),
      ),
      centerTitle: true,
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'pag',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const TextSpan(
              text: 'bus',
              style: TextStyle(
                color: Color(0xFF103038),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      actions: const [SizedBox(width: 56)],
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Histórico de Viagens',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String valor) {
              setState(() {
                _filtroSelecionado = valor;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Recentes',
                child: Text('Recentes'),
              ),
              const PopupMenuItem<String>(
                value: 'Semana Passada',
                child: Text('Semana Passada'),
              ),
              const PopupMenuItem<String>(
                value: 'Mês Passado',
                child: Text('Mês Passado'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _filtroSelecionado,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('passagens')
          .orderBy('data', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'Nenhuma passagem utilizada ainda.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final dados = docs[index].data() as Map<String, dynamic>;

            // TRATAMENTO SEGURO DA DATA
            String horaFormatada = '--:--';
            if (dados['data'] != null) {
              final campoData = dados['data'];

              if (campoData is Timestamp) {
                horaFormatada = DateFormat(
                  'HH:mm\'H\'',
                ).format(campoData.toDate());
              } else if (campoData is String) {
                try {
                  final dataObjeto = DateTime.parse(campoData);
                  horaFormatada = DateFormat('HH:mm\'H\'').format(dataObjeto);
                } catch (_) {
                  final regexHora = RegExp(r'(\d{2}):(\d{2})');
                  final match = regexHora.firstMatch(campoData);
                  if (match != null) {
                    horaFormatada = '${match.group(0)}H';
                  } else {
                    horaFormatada = 'Viagem';
                  }
                }
              }
            }

            // Tratamento do Valor
            String valorFormatado = 'R\$ 0,00';
            if (dados['valor'] != null) {
              final valor = dados['valor'];
              valorFormatado = valor is num
                  ? 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'
                  : 'R\$ $valor';
            }

            // Pegando os textos salvos
            String linha = dados['linha'] ?? 'Linha Não Identificada';

            // Coleta a Empresa direto do Banco se o campo existir
            String empresa = dados['empresa'] ?? '';
            Color corEmpresa;

            // Fallback: Se o campo 'empresa' estiver vazio no banco, deduz pela linha
            if (empresa.isEmpty) {
              if (linha.toUpperCase().contains('UNIPAMPA') ||
                  linha.toUpperCase().contains('ANVERSA')) {
                empresa = 'ANVERSA';
              } else if (linha.toUpperCase().contains('STADTBUS')) {
                empresa = 'STADTBUS';
              } else {
                empresa = 'OUTRA';
              }
            }

            // CONDICIONAL DE COR (Anversa = Amarelo, Stadtbus = Azul, Outros = Verde do App)
            if (empresa.toUpperCase().contains('ANVERSA')) {
              corEmpresa = const Color(0xFFFFE600); // Amarelo Anversa Idêntico
            } else if (empresa.toUpperCase().contains('STADTBUS')) {
              corEmpresa = const Color(0xFF003399); // Azul Stadtbus Idêntico
            } else {
              corEmpresa = const Color(0xFF4CAF50); // Verde padrão do App
            }

            final transactionMap = {
              'company': empresa,
              'line': 'Linha $linha',
              'time': horaFormatada,
              'amount':
                  '-$valorFormatado', // Adicionado o menos idêntico aos Meus Gastos
              'bgColor': corEmpresa,
            };

            return _TransactionItem(
              transaction: transactionMap,
              showDivider: index < docs.length - 1,
            );
          },
        );
      },
    );
  }

  BottomAppBar _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.white,
      elevation: 0,
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.grey,
            ),
            onPressed: () async {},
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExpensesScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsCenterScreen(
                    userId: widget.userId,
                  ), // Você pode passar o userId se precisar filtrar as notificações por usuári
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time_outlined, color: Colors.grey),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchedulesScreen(userId: widget.userId),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGETS DE COMPONENTES INTERNOS (_BalanceCard e _TransactionItem)
// ============================================================================

class _BalanceCard extends StatelessWidget {
  final String userId;
  final String defaultName;

  const _BalanceCard({
    Key? key,
    required this.userId,
    required this.defaultName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _FlippableBalanceCard(userId: userId, defaultName: defaultName);
  }
}

class _FlippableBalanceCard extends StatefulWidget {
  final String userId;
  final String defaultName;

  const _FlippableBalanceCard({
    Key? key,
    required this.userId,
    required this.defaultName,
  }) : super(key: key);

  @override
  State<_FlippableBalanceCard> createState() => _FlippableBalanceCardState();
}

class _FlippableBalanceCardState extends State<_FlippableBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _showQrCode = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_showQrCode) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
    setState(() {
      _showQrCode = !_showQrCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animation = Tween<double>(
          begin: 0,
          end: pi,
        ).evaluate(_animationController);

        final perspective = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(animation);

        final shouldShowBack = animation > pi / 2;

        return Transform(
          transform: perspective,
          alignment: Alignment.center,
          child: Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: shouldShowBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _CardBack(
                      onTapBack: _toggleFlip,
                      userId: widget.userId,
                    ),
                  )
                : _CardFront(
                    onTapQrCode: _toggleFlip,
                    userId: widget.userId,
                    defaultName: widget.defaultName,
                  ),
          ),
        );
      },
    );
  }
}

class _CardFront extends StatelessWidget {
  final VoidCallback onTapQrCode;
  final String userId;
  final String defaultName;

  const _CardFront({
    Key? key,
    required this.onTapQrCode,
    required this.userId,
    required this.defaultName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          String saldo = "R\$ 0,00";
          String nome = defaultName;

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;

            if (data['saldo'] != null) {
              final valorSaldo = data['saldo'];
              if (valorSaldo is num) {
                saldo =
                    "R\$ ${valorSaldo.toStringAsFixed(2).replaceAll('.', ',')}";
              } else {
                saldo = "R\$ $valorSaldo";
              }
            }
            nome = data['name'] ?? data['nome'] ?? defaultName;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Atual',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        saldo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nome,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 130,
                    height: 130,
                    child: Transform.translate(
                      offset: const Offset(52, -45),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          'assets/images/bussemfundo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onTapQrCode,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'QRCode',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  final VoidCallback onTapBack;
  final String userId;

  const _CardBack({Key? key, required this.onTapBack, required this.userId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: QrImageView(
              data: userId,
              version: QrVersions.auto,
              size: 104,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: const Duration(milliseconds: 250),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return QrCodeFullScreen(qrData: userId);
                      },
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.open_in_full,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onTapBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool showDivider;

  const _TransactionItem({
    Key? key,
    required this.transaction,
    required this.showDivider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String empresa = transaction['company'] as String;
    final Color corLogo = transaction['bgColor'] as Color;

    Widget logoWidget = const Icon(Icons.directions_bus, color: Colors.white);

    if (empresa.toUpperCase().contains('ANVERSA')) {
      logoWidget = const Text(
        'anversa',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      );
    } else if (empresa.toUpperCase().contains('STADTBUS')) {
      logoWidget = const Text(
        'stadtbus',
        style: TextStyle(
          fontSize: 9,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: corLogo,
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: logoWidget,
              ),
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction['time'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction['line'] as String,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Text(
            transaction['amount'] as String,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF103038), // Cor escura idêntica aos Meus Gastos
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[200], height: 1, thickness: 0.5),
          ),
      ],
    );
  }
}
