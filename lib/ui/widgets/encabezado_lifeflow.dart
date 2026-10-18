import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Encabezado de la pantalla principal: botón para regresar, logo y nombre de la app.
class EncabezadoLifeFlow extends StatelessWidget {
  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  const EncabezadoLifeFlow({
    super.key,
    required this.escala,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Row(
        children: [
          // Botón para regresar a la pantalla de perfiles.
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              tooltip: 'Regresar',
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colores.texto,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Logo de la app.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colores.principal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Nombre de la app y su descripción.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VoiceNotes',
                  style: TextStyle(
                    fontSize: 22 * escala,
                    fontWeight: FontWeight.w800,
                    color: colores.texto,
                  ),
                ),
                Text(
                  'Tu asistente personal',
                  style: TextStyle(
                    fontSize: 11 * escala,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
