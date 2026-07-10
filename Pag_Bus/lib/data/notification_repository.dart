import 'package:flutter_application_1/models/notification.dart';

/// Repository for managing notifications in PagBus.
///
/// Uses a static list as the single source of truth for all notifications.
/// This pattern ensures that notifications persist when navigating between screens
/// without the need for external state management libraries.
/// The list is created once at app startup and lives for the app's entire lifetime.
/// Mock data is sorted newest-first (today at top, older dates below).
class NotificationRepository {
  // Single source of truth: all notifications live here for the app's entire lifetime.
  // Pre-sorted newest-first by timestamp.
  static final List<PagBusNotification> _notifications = [
    // ===== TODAY (Junho 15, 2026) =====
    PagBusNotification(
      id: 'notif_001',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$55,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 15, 14, 32, 0),
    ),
    PagBusNotification(
      id: 'notif_002',
      type: 'line_info',
      title: 'PagBus',
      message: 'Atualização de horário',
      lineNumber: 'Linha Unipampa',
      timestamp: DateTime(2026, 6, 15, 12, 15, 0),
    ),
    PagBusNotification(
      id: 'notif_003',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$40,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 15, 9, 45, 0),
    ),
    PagBusNotification(
      id: 'notif_004',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$30,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 15, 8, 20, 0),
    ),

    // ===== YESTERDAY (Junho 14, 2026) =====
    PagBusNotification(
      id: 'notif_005',
      type: 'payment_canceled',
      title: 'Pagamento Cancelado',
      message: 'Refaça sua recarga',
      timestamp: DateTime(2026, 6, 14, 18, 50, 0),
    ),
    PagBusNotification(
      id: 'notif_006',
      type: 'line_info',
      title: 'PagBus',
      message: 'Alteração de rota',
      lineNumber: 'Linha Centro',
      timestamp: DateTime(2026, 6, 14, 15, 30, 0),
    ),
    PagBusNotification(
      id: 'notif_007',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$50,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 14, 11, 0, 0),
    ),
    PagBusNotification(
      id: 'notif_008',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$25,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 14, 9, 15, 0),
    ),

    // ===== FRIDAY (Junho 13, 2026) =====
    PagBusNotification(
      id: 'notif_009',
      type: 'payment_canceled',
      title: 'Pagamento Cancelado',
      message: 'Refaça sua recarga',
      timestamp: DateTime(2026, 6, 13, 16, 45, 0),
    ),
    PagBusNotification(
      id: 'notif_010',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$60,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 13, 10, 30, 0),
    ),

    // ===== THURSDAY (Junho 12, 2026) =====
    PagBusNotification(
      id: 'notif_011',
      type: 'line_info',
      title: 'PagBus',
      message: 'Manutenção programada',
      lineNumber: 'Linha Norte',
      timestamp: DateTime(2026, 6, 12, 14, 0, 0),
    ),
    PagBusNotification(
      id: 'notif_012',
      type: 'payment_received',
      title: 'Pagamento Recebido',
      message: '+R\$45,00 - Seu saldo foi atualizado',
      timestamp: DateTime(2026, 6, 12, 9, 0, 0),
    ),
  ];

  /// Returns all notifications sorted newest-first.
  /// The list is already pre-sorted at initialization.
  static List<PagBusNotification> getAll() {
    return _notifications;
  }
}
