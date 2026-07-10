import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORTADO PARA INTERAGIR COM O BANCO

class RechargeScreen extends StatefulWidget {
  // 1. REQUERIDO: Agora a tela exige o ID do respectivo usuário logado
  final String userId;

  const RechargeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  static const List<Map<String, dynamic>> _predefinedOptions = [
    {'label': '1 passagem', 'price': 5.50},
    {'label': '2 passagens', 'price': 11.00},
    {'label': '4 passagens', 'price': 22.00},
    {'label': '6 passagens', 'price': 33.00},
    {'label': '10 passagens', 'price': 55.00},
    {'label': '15 passagens', 'price': 82.50},
  ];

  int _selectedOptionIndex = 0;
  bool _isCustomValue = false;
  late TextEditingController _customValueController;
  late Timer _timer;
  int _remainingSeconds = 900;
  bool _isProcessingPayment = false; // Controle de loading no botão

  @override
  void initState() {
    super.initState();
    _customValueController = TextEditingController();
    _startTimer();
  }

  @override
  void dispose() {
    _customValueController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _showTimeExpiredSnackBar();
          _timer.cancel();
        }
      });
    });
  }

  void _showTimeExpiredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tempo esgotado. Gere um novo código.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _isCustomValue = false;
      _customValueController.clear();
    });
  }

  void _selectCustomValue() {
    setState(() {
      _isCustomValue = true;
    });
  }

  double _getSelectedPrice() {
    if (_isCustomValue) {
      final text = _customValueController.text.replaceAll(
        RegExp(r'[^\d,]'),
        '',
      );
      if (text.isNotEmpty) {
        return double.tryParse(text.replaceAll(',', '.')) ?? 0.0;
      }
      return 0.0;
    }
    return _predefinedOptions[_selectedOptionIndex]['price'] as double;
  }

  String _getSelectedLabel() {
    if (_isCustomValue) {
      return 'valor personalizado';
    }
    return _predefinedOptions[_selectedOptionIndex]['label'] as String;
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  String _generatePixPayload() {
    // Pegamos o valor apenas para manter a lógica viva no console se precisar
    final amount = (_getSelectedPrice() * 100).toInt();

    // Retorna uma string comum sem caracteres especiais que confundem o Dart
    return '00020126580014br.gov.bcb.brcode01051.0.053063047D5D11B44503000170740510-PAGBUS-VALOR-$amount-63041D3D';
  }

  void _copyPixCode() {
    final pixCode = _generatePixPayload();
    Clipboard.setData(ClipboardData(text: pixCode)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código copiado!'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  // INTERAÇÃO REAL COM O BANCO DE DADOS FIRESTORE
  // INTERAÇÃO REAL COM O BANCO DE DADOS FIRESTORE + CRIAÇÃO DE NOTIFICAÇÃO
  Future<void> _confirmPayment() async {
    final selectedPrice = _getSelectedPrice();

    if (selectedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Selecione ou digite um valor válido para recarga.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // Usaremos um lote (WriteBatch) para garantir que ou salva tudo ou nada
      final batch = FirebaseFirestore.instance.batch();

      // 1. Referência para atualizar o saldo do usuário
      final userDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId);

      batch.update(userDocRef, {'saldo': FieldValue.increment(selectedPrice)});

      // 2. Referência para criar uma nova notificação (ID gerado automaticamente pelo .doc())
      final notificationDocRef = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.userId)
          .collection('notificacoes')
          .doc();

      batch.set(notificationDocRef, {
        'id': notificationDocRef.id,
        'titulo': 'Recarga Confirmada! 🎉',
        'mensagem':
            'Sua recarga no valor de ${_formatCurrency(selectedPrice)} foi processada com sucesso e já está disponível.',
        'valor': selectedPrice,
        'tipo': 'recarga',
        'lido': false, // Útil para colocar aquela bolinha de não lido no app
        'criadoEm': FieldValue.serverTimestamp(),
      });

      // Executa as duas ações juntas no banco
      await batch.commit();

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      // SnackBar visual verde de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Recarga de ${_formatCurrency(selectedPrice)} adicionada com sucesso!',
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );

      // Fecha a tela de recarga e volta para a HomeScreen
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Falha ao processar créditos e notificação: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escolha o valor da recarga',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              _buildRechargeGrid(),
              const SizedBox(height: 24),

              _RechargeSummary(
                selectedLabel: _getSelectedLabel(),
                selectedPrice: _getSelectedPrice(),
                formatCurrency: _formatCurrency,
              ),
              const SizedBox(height: 24),

              _PixPaymentSection(
                pixPayload: _generatePixPayload(),
                selectedPrice: _getSelectedPrice(),
                onCopyCode: _copyPixCode,
              ),
              const SizedBox(height: 24),

              _buildExpirationTimer(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildConfirmButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF5BBF4E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Recarga de Passagens',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Icon(Icons.confirmation_number_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRechargeGrid() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: List.generate(_predefinedOptions.length, (index) {
            final option = _predefinedOptions[index];
            final isSelected = _selectedOptionIndex == index && !_isCustomValue;
            return _RechargeOptionCard(
              label: option['label'] as String,
              price: option['price'] as double,
              isSelected: isSelected,
              formatCurrency: _formatCurrency,
              onTap: () => _selectOption(index),
            );
          }),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _selectCustomValue,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: _isCustomValue
                    ? const Color(0xFF7C4DFF)
                    : const Color(0xFFE0E0E0),
                width: _isCustomValue ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Outro Valor',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customValueController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'R\$ 0,00',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4CAF50),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      _selectCustomValue();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpirationTimer() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(Icons.access_time, color: Colors.grey[600], size: 18),
        const SizedBox(width: 8),
        Text(
          'Este pagamento expira em ',
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
        Text(
          timeFormatted,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ElevatedButton(
          onPressed: _isProcessingPayment ? null : _confirmPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5BBF4E),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessingPayment
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Confirmar pagamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _RechargeOptionCard extends StatelessWidget {
  final String label;
  final double price;
  final bool isSelected;
  final Function(double) formatCurrency;
  final VoidCallback onTap;

  const _RechargeOptionCard({
    Key? key,
    required this.label,
    required this.price,
    required this.isSelected,
    required this.formatCurrency,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C4DFF)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(price),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RechargeSummary extends StatelessWidget {
  final String selectedLabel;
  final double selectedPrice;
  final Function(double) formatCurrency;

  const _RechargeSummary({
    Key? key,
    required this.selectedLabel,
    required this.selectedPrice,
    required this.formatCurrency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Você está recarregando',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                selectedLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE0E0E0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor da recarga',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                formatCurrency(selectedPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFE0E0E0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forma de pagamento',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_2, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'PIX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PixPaymentSection extends StatelessWidget {
  final String pixPayload;
  final double selectedPrice;
  final VoidCallback onCopyCode;

  const _PixPaymentSection({
    Key? key,
    required this.pixPayload,
    required this.selectedPrice,
    required this.onCopyCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pague com o PIX',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.grey[900],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: pixPayload,
                  version: QrVersions.auto,
                  size: 120,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escaneie o QR Code com o app do seu banco',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ou copie o código abaixo',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onCopyCode,
                      child: const Row(
                        children: [
                          Text(
                            'Copiar código',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.copy, color: Color(0xFF4CAF50), size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
