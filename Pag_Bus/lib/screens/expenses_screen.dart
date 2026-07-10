import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notifications_center_screen.dart';
import 'recharge_screen.dart';
import 'schedules_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final String userId;

  const ExpensesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _mesSelecionado = '';

  @override
  void initState() {
    super.initState();
    // Define o mês atual em português com a primeira letra maiúscula (Ex: "Junho")
    String mesAtual = DateFormat('MMMM', 'pt_BR').format(DateTime.now());
    _mesSelecionado = mesAtual[0].toUpperCase() + mesAtual.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.userId)
            .collection('passagens')
            .orderBy('data', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar banco: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // Mapa dinâmico para acumular gastos por mês curto (Jan, Fev, Mar...)
          Map<String, double> gastosPorMes = {};
          double totalMesAtual = 0.0;
          List<Map<String, dynamic>> passagensFiltradas = [];

          for (var doc in docs) {
            final dados = doc.data() as Map<String, dynamic>;

            // 1. Tratamento do valor numérico
            double valor = 0.0;
            if (dados['valor'] != null) {
              if (dados['valor'] is num) {
                valor = (dados['valor'] as num).toDouble();
              } else {
                String valorLimpo = dados['valor'].toString().replaceAll(
                  ',',
                  '.',
                );
                valor = double.tryParse(valorLimpo) ?? 0.0;
              }
            }

            // 2. Tratamento nativo do Timestamp do Firestore
            if (dados['data'] != null && dados['data'] is Timestamp) {
              DateTime dataItem = (dados['data'] as Timestamp).toDate();

              // Nome curto do mês para o gráfico (ex: "Jun")
              String mesCurto = _getMesCurto(dataItem.month);
              gastosPorMes[mesCurto] = (gastosPorMes[mesCurto] ?? 0.0) + valor;

              // Nome completo para o filtro (ex: "Junho")
              String nomeMesItem = DateFormat('MMMM', 'pt_BR').format(dataItem);
              nomeMesItem =
                  nomeMesItem[0].toUpperCase() + nomeMesItem.substring(1);

              // Filtra pelo mês selecionado no Dropdown
              if (nomeMesItem.trim().toLowerCase() ==
                  _mesSelecionado.trim().toLowerCase()) {
                totalMesAtual += valor;
                dados['dateTimeProcessada'] =
                    dataItem; // guarda para a lista inferior
                passagensFiltradas.add(dados);
              }
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildChartCard(gastosPorMes, totalMesAtual),
                _buildMonthSelector(),
                _buildFilteredList(passagensFiltradas),
              ],
            ),
          );
        },
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF7CD959),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Meus gastos',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.bar_chart, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildChartCard(Map<String, double> gastosPorMes, double totalMes) {
    // Garante que o gráfico mostre ao menos os meses populados ou uma lista padrão vazia
    List<String> mesesExibidos = gastosPorMes.keys.toList();
    if (mesesExibidos.isEmpty) mesesExibidos = ['Jan', 'Fev', 'Mar', 'Abr'];

    double valorMaximo = gastosPorMes.values.fold(
      0,
      (max, e) => e > max ? e : max,
    );
    if (valorMaximo == 0) valorMaximo = 1.0;

    String totalFormatado =
        "-R\$ ${totalMes.toStringAsFixed(2).replaceAll('.', ',')}";

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Gastos esse mês',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                totalFormatado,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height:
                180, // Aumentado ligeiramente para dar espaço aos números no topo
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: mesesExibidos.map((mes) {
                double valorMes = gastosPorMes[mes] ?? 0.0;
                double percentualAltura = valorMes / valorMaximo;

                // Formata o valor individual da barra (Ex: "5,50" ou "0")
                String valorBarraFormatado = valorMes > 0
                    ? valorMes.toStringAsFixed(2).replaceAll('.', ',')
                    : '0';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Exibe o número/valor bem em cima da barra
                    Text(
                      valorMes > 0 ? 'R\$ $valorBarraFormatado' : 'R\$ 0',
                      style: TextStyle(
                        color: valorMes > 0
                            ? const Color(0xFF103038)
                            : Colors.grey,
                        fontSize: 10,
                        fontWeight: valorMes > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: 40,
                        alignment: Alignment.bottomCenter,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7CD959),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: EdgeInsets.only(
                          top:
                              130 *
                              (1 -
                                  percentualAltura), // Ajustado o multiplicador para o novo layout
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mes,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    List<String> mesesAno = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DropdownButton<String>(
            value: mesesAno.contains(_mesSelecionado)
                ? _mesSelecionado
                : mesesAno[DateTime.now().month - 1],
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
            underline: const SizedBox(),
            elevation: 2,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            onChanged: (String? novoValor) {
              if (novoValor != null) {
                setState(() {
                  _mesSelecionado = novoValor;
                });
              }
            },
            items: mesesAno.map<DropdownMenuItem<String>>((String valor) {
              return DropdownMenuItem<String>(value: valor, child: Text(valor));
            }).toList(),
          ),
        ],
      ),
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
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
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
                  builder: (_) =>
                      NotificationsCenterScreen(userId: widget.userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time_outlined, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SchedulesScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredList(List<Map<String, dynamic>> passagens) {
    if (passagens.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Nenhum gasto em $_mesSelecionado',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: passagens.length,
      itemBuilder: (context, index) {
        final dados = passagens[index];

        String horaFormatada = '16:00H';
        if (dados['dateTimeProcessada'] != null) {
          horaFormatada = DateFormat(
            'HH:mm\'H\'',
          ).format(dados['dateTimeProcessada'] as DateTime);
        }

        String valorFormatado = '-R\$ 5,50';
        if (dados['valor'] != null) {
          final valor = dados['valor'];
          valorFormatado = valor is num
              ? '-R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}'
              : '-R\$ $valor';
        }

        String linha = dados['linha'] ?? 'Unipampa';
        String empresa = dados['empresa'] ?? '';

        if (empresa.isEmpty) {
          if (linha.toUpperCase().contains('UNIPAMPA') ||
              linha.toUpperCase().contains('ANVERSA')) {
            empresa = 'ANVERSA';
          } else if (linha.toUpperCase().contains('STADTBUS')) {
            empresa = 'STADTBUS';
          }
        }

        Color corLogo = const Color(0xFF4CAF50);
        Widget logoWidget = const Icon(
          Icons.directions_bus,
          color: Colors.white,
        );

        if (empresa.toUpperCase().contains('ANVERSA')) {
          corLogo = const Color(0xFFFFE600);
          logoWidget = const Text(
            'anversa',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          );
        } else if (empresa.toUpperCase().contains('STADTBUS')) {
          corLogo = const Color(0xFF003399);
          logoWidget = const Text(
            'stadtbus',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
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
            title: Text(
              horaFormatada,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            subtitle: Text(
              'Linha $linha',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: Text(
              valorFormatado,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF103038),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMesCurto(int numeroMes) {
    const meses = {
      1: 'Jan',
      2: 'Fev',
      3: 'Mar',
      4: 'Abr',
      5: 'Mai',
      6: 'Jun',
      7: 'Jul',
      8: 'Ago',
      9: 'Set',
      10: 'Out',
      11: 'Nov',
      12: 'Dez',
    };
    return meses[numeroMes] ?? 'Jan';
  }
}
