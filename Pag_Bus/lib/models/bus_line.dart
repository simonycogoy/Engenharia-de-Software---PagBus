/// Model representing a bus line with schedule information.
///
/// Holds line details (company, origin, destination) and schedules for
/// both outbound and return trips across different day types.
/// The [isFavorite] field allows users to mark favorite lines.
class BusLine {
  final String id;
  final String company; // 'anversa' or 'stadtbus'
  final String lineNumber; // e.g. "Linha 3"
  final String origin; // e.g. "Ivo Ferronato"
  final String destination; // e.g. "Arvorezinha"
  final String outboundHeader; // e.g. "Saídas do Ivo Ferronato/Unipampa"
  final String returnHeader; // e.g. "Saídas do Fênix/Arvorezinha"
  final Map<String, List<String>>
  outboundSchedule; // keys: 'weekday', 'saturday', 'sundayHoliday'
  final Map<String, List<String>> returnSchedule; // same keys
  bool isFavorite;

  BusLine({
    required this.id,
    required this.company,
    required this.lineNumber,
    required this.origin,
    required this.destination,
    required this.outboundHeader,
    required this.returnHeader,
    required this.outboundSchedule,
    required this.returnSchedule,
    this.isFavorite = false,
  });
}
