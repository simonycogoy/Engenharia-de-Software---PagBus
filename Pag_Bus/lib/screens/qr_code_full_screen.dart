import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeFullScreen extends StatelessWidget {
  final String qrData;

  const QrCodeFullScreen({Key? key, required this.qrData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF5BBF4E),
      body: SafeArea(
        child: Column(
          children: [
            // Top section: back button and bus icon badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bus icon badge (centered horizontally in remaining space)
                  const _BusIconBadge(),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Center: large QR code
            Expanded(
              child: Center(
                child: Transform.translate(
                  offset: const Offset(0, -80), // sobe o QR
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final qrSize = (constraints.maxWidth * 0.75).clamp(
                        200.0,
                        400.0,
                      );
                      return Container(
                        width: qrSize,
                        height: qrSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar - reused from HomeScreen
      //bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds the bottom navigation bar (reused from HomeScreen)
  /*BottomAppBar _buildBottomNavigationBar() {
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          const SizedBox(width: 48), // Space for FAB
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.access_time_outlined, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
    );
  }*/
}

/// Bus icon badge widget (reused from _CardBack)
class _BusIconBadge extends StatelessWidget {
  const _BusIconBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Transform.translate(
        offset: const Offset(-20, -30), // ajuste aqui
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(
            'assets/images/logosemfundo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
