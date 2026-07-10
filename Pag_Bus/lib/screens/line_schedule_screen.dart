import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bus_line.dart';
import 'package:flutter_application_1/data/bus_line_repository.dart';
import 'package:flutter_application_1/widgets/line_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen showing detailed schedule information for a specific bus line.
///
/// Displays the line's outbound and return schedules with a day-type selector
/// (weekday, saturday, or sunday/holiday). The screen colors are theme-colored
/// based on the bus company (green for Anversa, blue for Stadtbus).
class LineScheduleScreen extends StatefulWidget {
  final String lineId;
  final String userId; // 👈 Adicionado o ID do usuário para salvar no banco

  const LineScheduleScreen({
    Key? key,
    required this.lineId,
    required this.userId,
  }) : super(key: key);

  @override
  State<LineScheduleScreen> createState() => _LineScheduleScreenState();
}

class _LineScheduleScreenState extends State<LineScheduleScreen> {
  late String _selectedDayType;

  @override
  void initState() {
    super.initState();
    _selectedDayType = 'weekday';
  }

  /// Função interna que liga/desliga o favorito na subcoleção do Firestore
  Future<void> _toggleFirestoreFavorite(bool isCurrentlyFavorite) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .collection('favoritos')
        .doc(widget.lineId);

    if (isCurrentlyFavorite) {
      // Se já for favorito, remove da subcoleção
      await docRef.delete();
    } else {
      // Se não for, cria o documento salvo com o id e a data de adição
      await docRef.set({
        'lineId': widget.lineId,
        'salvoEm': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = BusLineRepository.getAll().firstWhere(
      (l) => l.id == widget.lineId,
    );

    final themeColor = line.company == 'anversa'
        ? const Color(0xFF5BBF4E)
        : const Color(0xFF1565C0);

    // O AppBar agora assume a cor dinâmica de forma idêntica à empresa
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('favoritos')
          .doc(widget.lineId)
          .snapshots(),
      builder: (context, snapshot) {
        // Se o documento existir dentro da subcoleção, significa que a linha está favoritada
        final bool isFavorite = snapshot.hasData && snapshot.data!.exists;

        // Atualiza temporariamente o repositório em memória para o LineCard renderizar a estrela certa
        line.isFavorite = isFavorite;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(themeColor),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFavoriteHint(isFavorite, themeColor),
                  const SizedBox(height: 16),
                  LineCard(
                    line: line,
                    onTap: null,
                    onFavoriteToggle: () =>
                        _toggleFirestoreFavorite(isFavorite),
                  ),
                  const SizedBox(height: 24),
                  _buildDayTypeSelector(themeColor),
                  const SizedBox(height: 24),
                  _buildScheduleSection(
                    line: line,
                    header: line.outboundHeader,
                    scheduleMap: line.outboundSchedule,
                    themeColor: themeColor,
                  ),
                  const SizedBox(height: 24),
                  _buildScheduleSection(
                    line: line,
                    header: line.returnHeader,
                    scheduleMap: line.returnSchedule,
                    themeColor: themeColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(Color themeColor) {
    return AppBar(
      backgroundColor:
          themeColor, // 👈 Agora altera dinamicamente com base na empresa
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
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFavoriteHint(bool isFavorite, Color themeColor) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFavorite ? Icons.bookmark : Icons.bookmark_border,
            color: themeColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isFavorite
                ? 'Linha salva nos favoritos'
                : 'Selecione a estrela para favoritar',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTypeSelector(Color themeColor) {
    const dayTypes = [
      ('weekday', 'Segunda à Sexta'),
      ('saturday', 'Sábados'),
      ('sundayHoliday', 'Domingo e Feriados'),
    ];

    return Row(
      children: dayTypes.map((dayType) {
        final key = dayType.$1;
        final label = dayType.$2;
        final isSelected = _selectedDayType == key;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDayType = key;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.white,
                  border: Border.all(color: themeColor, width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : themeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleSection({
    required BusLine line,
    required String header,
    required Map<String, List<String>> scheduleMap,
    required Color themeColor,
  }) {
    final times = scheduleMap[_selectedDayType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            header,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFEFEF),
                borderRadius: BorderRadius.circular(16),
              ),
              constraints: const BoxConstraints(minWidth: 56),
              child: Center(
                child: Text(
                  time,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
