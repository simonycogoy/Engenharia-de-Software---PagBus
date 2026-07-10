import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Importe o Firebase Core
import 'package:flutter_application_1/screens/signup_screen.dart';
import 'firebase_options.dart'; // 2. Importe as opções geradas pelo CLI
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
//import 'screens/home_screen.dart';
//import 'screens/signup_screen.dart';

void main() async {
  // 3. Garante que os bindings do Flutter estejam prontos antes de iniciar o Firebase
  await initializeDateFormatting('pt_BR', null);

  WidgetsFlutterBinding.ensureInitialized();

  // 4. Inicializa o Firebase com as configurações automáticas
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PagBusApp());
}

class PagBusApp extends StatelessWidget {
  const PagBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PagBus",
      home: LoginScreen(),
    );
  }
}
