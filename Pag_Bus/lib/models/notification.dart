/// Data model for a single notification in PagBus.
///
/// Holds information about payment updates, cancellations, and line information.
/// The [type] field categorizes the notification, and [lineNumber] is used
/// specifically for 'line_info' type notifications.
class PagBusNotification {
  final String id;
  final String type; // 'payment_received' | 'payment_canceled' | 'line_info'
  final String title; // e.g. "Pagamento Recebido"
  final String message; // e.g. "Seu saldo foi atualizado"
  final DateTime timestamp;
  final String? lineNumber; // optional, used for type == 'line_info'

  PagBusNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.lineNumber,
  });
}
