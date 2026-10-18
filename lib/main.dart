import 'package:flutter/material.dart';

import 'services/notificaciones_service.dart';
import 'ui/screens/pantalla_seleccion_perfil.dart';

/// Punto de entrada de la app: deja listo lo necesario y muestra la primera pantalla.
Future<void> main() async {
  // Necesario para usar funciones del celular antes de que arranque la app.
  WidgetsFlutterBinding.ensureInitialized();

  // Deja listas las notificaciones de Android.
  await NotificacionesService.inicializar();

  // Arranca la app.
  runApp(const LifeFlowApp());
}

/// Raíz de la app: define el nombre, el tema general y la primera pantalla.
class LifeFlowApp extends StatelessWidget {
  const LifeFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VoiceNotes',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        fontFamily: 'Roboto',
      ),
      // Lo primero que ve la persona es la pantalla para elegir su perfil.
      home: const PantallaSeleccionPerfil(),
    );
  }
}
