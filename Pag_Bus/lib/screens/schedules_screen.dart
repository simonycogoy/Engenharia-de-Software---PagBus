import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bus_line.dart';
import 'package:flutter_application_1/data/bus_line_repository.dart';
import 'package:flutter_application_1/widgets/line_card.dart';
import 'line_schedule_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expenses_screen.dart';
import 'notifications_center_screen.dart';
import 'recharge_screen.dart';

/// Screen for browsing bus lines grouped by company or showing favorites.
///
/// Displays a company selector (Anversa/Stadtbus) and conditionally shows
/// a list of lines. When no company is selected, only favorite lines are shown
/// (if any exist). When a company is selected, that company's lines are shown
/// with favorites sorted to the top.
class SchedulesScreen extends StatefulWidget {
  final String userId; // 👈 Adicionado o ID do usuário conectado

  const SchedulesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  String? _selectedCompany; // null = no selection, 'anversa', or 'stadtbus'

  /// Liga ou desliga o favorito diretamente na subcoleção do Firestore
  Future<void> _toggleFirestoreFavorite(
    String lineId,
    bool isCurrentlyFavorite,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('favoritos')
        .doc(lineId);

    if (isCurrentlyFavorite) {
      await docRef.delete();
    } else {
      // Guarda informações básicas da linha favoritada para indexação se necessário
      await docRef.set({
        'lineId': lineId,
        'salvoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta em tempo real os favoritos do usuário corrente
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('favoritos')
          .snapshots(),
      builder: (context, snapshot) {
        // Cria um set com as IDs das linhas favoritadas para busca rápida O(1)
        final Set<String> idsFavoritas = {};
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            idsFavoritas.add(doc.id);
          }
        }

        // Sincroniza o estado em memória das linhas com os dados vindos do Firestore
        final todasAsLinhas = BusLineRepository.getAll();
        for (var line in todasAsLinhas) {
          line.isFavorite = idsFavoritas.contains(line.id);
        }

        // Obtém a lista final de linhas ordenadas/filtradas conforme as regras
        final linesList = _buildLinesList();

        return Scaffold(
          bottomNavigationBar: _buildBottomNavigationBar(context),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
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
          appBar: _buildAppBar(),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company selector
                  _buildCompanySelector(),
                  const SizedBox(height: 24),
                  // Lines section (conditionally visible)
                  if (linesList.isNotEmpty) ...[
                    const Text(
                      'Selecione para visualizar horários',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLinesListView(linesList),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF5BBF4E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Horários',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.access_time, color: Colors.white),
          onPressed: () {}, // Decorative
        ),
      ],
    );
  }

  Widget _buildCompanySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione para visualizar linhas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompanyCard(
                label: 'Anversa',
                company: 'anversa',
                backgroundColor: const Color.fromARGB(255, 1, 167, 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompanyCard(
                label: 'Stadtbus',
                company: 'stadtbus',
                backgroundColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompanyCard({
    required String label,
    required String company,
    required Color backgroundColor,
  }) {
    final isSelected = _selectedCompany == company;
    final borderColor = isSelected ? backgroundColor : const Color(0xFFE0E0E0);
    final borderWidth = isSelected ? 2.0 : 1.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedCompany == company) {
            _selectedCompany = null; // Toggle off
          } else {
            _selectedCompany = company; // Select this company
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: backgroundColor,
              child: const Icon(
                Icons.directions_bus,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
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
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  /// Builds the list of lines to display based on current selection.
  List<BusLine> _buildLinesList() {
    if (_selectedCompany == null) {
      // Retorna os favoritos coletando o estado atualizado em tempo real
      return BusLineRepository.getFavorites();
    } else {
      // Retorna as linhas da empresa correspondente com as favoritas no topo
      final allLines = BusLineRepository.getByCompany(_selectedCompany!);
      final favs = allLines.where((l) => l.isFavorite).toList();
      final nonFavs = allLines.where((l) => !l.isFavorite).toList();
      return [...favs, ...nonFavs];
    }
  }

  Widget _buildLinesListView(List<BusLine> lines) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index];
        return LineCard(
          line: line,
          onTap: () async {
            // Navega para os horários passando o lineId e o userId necessário
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LineScheduleScreen(lineId: line.id, userId: widget.userId),
              ),
            );
          },
          onFavoriteToggle: () {
            // Executa a inversão segura direto no FirebaseFirestore
            _toggleFirestoreFavorite(line.id, line.isFavorite);
          },
        );
      },
    );
  }
}
