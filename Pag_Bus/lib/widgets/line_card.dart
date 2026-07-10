import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/bus_line.dart';

/// Shared widget for displaying a bus line with route and favorite indicator.
///
/// Used in both SchedulesScreen (where onTap navigates) and LineScheduleScreen
/// (where onTap is null for display-only mode).
///
/// - Leading badge: Company-colored (yellow for Anversa, blue for Stadtbus)
///   with location icon and line number
/// - Middle: Route info (origin → destination) with dashed connector
/// - Trailing: Star icon to toggle favorite (green when favorited, gray otherwise)
/// - The card body (excluding star) is tappable when onTap is provided
class LineCard extends StatelessWidget {
  final BusLine line;
  final VoidCallback? onTap;
  final VoidCallback onFavoriteToggle;

  const LineCard({
    Key? key,
    required this.line,
    this.onTap,
    required this.onFavoriteToggle,
  }) : super(key: key);

  Color _getCompanyColor() {
    return line.company == 'anversa'
        ? const Color(0xFFFFC107)
        : const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Expanded body (everything except star) is wrapped in InkWell
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Leading badge: company logo + line number
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCompanyColor(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_pin,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            line.lineNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Middle: dashed line connector + route info
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dashed vertical line
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  3,
                                  (i) => Container(
                                    width: 1.5,
                                    height: 4,
                                    color: const Color(0xFFCCCCCC),
                                  ),
                                ),
                              );
                            },
                          ),
                          // Downward arrow overlay
                          const Icon(
                            Icons.arrow_downward,
                            size: 14,
                            color: Color(0xFF999999),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Route info: origin and destination
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.origin,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            line.destination,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Trailing: star icon for favorite toggle
          IconButton(
            icon: Icon(
              line.isFavorite ? Icons.star : Icons.star_border,
              color: line.isFavorite ? const Color(0xFF5BBF4E) : Colors.grey,
              size: 24,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
    );
  }
}
