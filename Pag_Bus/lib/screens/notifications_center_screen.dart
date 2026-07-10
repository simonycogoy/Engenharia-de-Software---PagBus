import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expenses_screen.dart';
import 'recharge_screen.dart';
import 'schedules_screen.dart';

// Modelo local acoplado de forma flexível aos campos gravados no Firestore
class PagBusNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'recarga', 'payment_canceled', 'line_info', etc.
  final DateTime timestamp;
  final String? lineNumber;

  PagBusNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.lineNumber,
  });

  factory PagBusNotification.fromFirestore(DocumentSnapshot doc) {
    final dados = doc.data() as Map<String, dynamic>;

    DateTime dataConvertida = DateTime.now();
    // Verifica de forma segura se o campo de data usado é 'criadoEm' ou 'data'
    final campoData = dados['criadoEm'] ?? dados['data'];
    if (campoData != null) {
      if (campoData is Timestamp) {
        dataConvertida = campoData.toDate();
      } else if (campoData is String) {
        dataConvertida = DateTime.tryParse(campoData) ?? DateTime.now();
      }
    }

    return PagBusNotification(
      id: doc.id,
      title: dados['titulo'] ?? 'Notificação',
      message: dados['mensagem'] ?? '',
      type: dados['tipo'] ?? 'system',
      timestamp: dataConvertida,
      lineNumber: dados['linha_numero'],
    );
  }
}

class NotificationsCenterScreen extends StatefulWidget {
  final String
  userId; // 👈 Exige o ID do usuário para consultar as notificações

  const NotificationsCenterScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  State<NotificationsCenterScreen> createState() =>
      _NotificationsCenterScreenState();
}

class _NotificationsCenterScreenState extends State<NotificationsCenterScreen> {
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
        // Escuta em tempo real a subcoleção de notificações filtrada por data decrecente
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(widget.userId)
            .collection('notificacoes')
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF5BBF4E)),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sua central de notificações está vazia.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Mapeia os documentos brutos para o nosso objeto local
          final notifications = docs
              .map((doc) => PagBusNotification.fromFirestore(doc))
              .toList();
          final groupedNotifications = _groupNotificationsByDate(notifications);

          return ListView.builder(
            itemCount: _calculateItemCount(groupedNotifications),
            itemBuilder: (context, index) {
              return _buildListItem(context, index, groupedNotifications);
            },
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
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: const Text(
        'Central de Notificações',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.notifications, color: Colors.white),
        ),
      ],
    );
  }

  Map<String, List<PagBusNotification>> _groupNotificationsByDate(
    List<PagBusNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<PagBusNotification>>{};

    for (final notif in notifications) {
      final notifDate = DateTime(
        notif.timestamp.year,
        notif.timestamp.month,
        notif.timestamp.day,
      );

      String dateLabel;
      if (notifDate == today) {
        dateLabel = 'Hoje';
      } else if (notifDate == yesterday) {
        dateLabel = 'Ontem';
      } else {
        dateLabel = DateFormat(
          'EEE, d \'de\' MMM',
          'pt_BR',
        ).format(notif.timestamp);

        final parts = dateLabel.split('.');
        if (parts.isNotEmpty) {
          dateLabel =
              parts[0][0].toUpperCase() +
              parts[0].substring(1) +
              '. ${parts.sublist(1).join('.')}';
        }
      }

      groups.putIfAbsent(dateLabel, () => []);
      groups[dateLabel]!.add(notif);
    }

    final sortedKeys = _sortDateLabels(groups.keys.toList(), today, yesterday);
    final sortedGroups = <String, List<PagBusNotification>>{};
    for (final key in sortedKeys) {
      sortedGroups[key] = groups[key]!;
    }
    return sortedGroups;
  }

  List<String> _sortDateLabels(
    List<String> labels,
    DateTime today,
    DateTime yesterday,
  ) {
    final sorted = [...labels];
    sorted.sort((a, b) {
      if (a == 'Hoje') return -1;
      if (b == 'Hoje') return 1;
      if (a == 'Ontem') return -1;
      if (b == 'Ontem') return 1;
      return b.compareTo(a);
    });
    return sorted;
  }

  int _calculateItemCount(Map<String, List<PagBusNotification>> grouped) {
    int count = 0;
    grouped.forEach((_, notifs) {
      count += 1 + notifs.length;
    });
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    Map<String, List<PagBusNotification>> grouped,
  ) {
    int currentIndex = 0;

    for (final dateLabel in grouped.keys) {
      final notifications = grouped[dateLabel]!;

      if (currentIndex == index) {
        return _buildDateHeader(dateLabel);
      }
      currentIndex++;

      for (final notif in notifications) {
        if (currentIndex == index) {
          return _buildNotificationCard(notif);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildDateHeader(String dateLabel) {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        dateLabel,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(PagBusNotification notif) {
    String horaMinuto = DateFormat('HH:mm').format(notif.timestamp);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationAvatar(notif.type),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      horaMinuto,
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif.type == 'line_info' && notif.lineNumber != null
                      ? 'Ônibus prefixo: ${notif.lineNumber}\n${notif.message}'
                      : notif.message,
                  style: const TextStyle(
                    color: Color(0xFF616161),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
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

  CircleAvatar _buildNotificationAvatar(String type) {
    switch (type) {
      case 'recarga': // Tipo de sucesso gerado na RechargeScreen
      case 'payment_received':
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
        );
      case 'payment_canceled':
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFFFEBEE),
          child: Icon(Icons.cancel, color: Color(0xFFE53935), size: 22),
        );
      case 'line_info': // Tipo disparado na hora do embarque em ônibus
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE3F2FD),
          child: Icon(Icons.directions_bus, color: Color(0xFF1565C0), size: 22),
        );
      default:
        return const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFF5F5F5),
          child: Icon(Icons.notifications, color: Colors.grey, size: 22),
        );
    }
  }
}
