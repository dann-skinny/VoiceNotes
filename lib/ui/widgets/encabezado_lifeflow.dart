
import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Encabezado principal de VoiceNotes.
class EncabezadoLifeFlow extends StatelessWidget {
  final double escala;
  final ColoresPerfil colores;

  const EncabezadoLifeFlow({
    super.key,
    required this.escala,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    final esAsistido = colores.esAdultoMayor;

    // Tamaños especiales para mejorar la accesibilidad.
    final tamanoTitulo = esAsistido ? 32.0 : 22.0;
    final tamanoSubtitulo = esAsistido ? 18.0 : 12.0;
    final tamanoIcono = esAsistido ? 34.0 : 26.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Row(
        children: [
          // Botón para regresar.
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              tooltip: 'Regresar',
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colores.texto,
                size: esAsistido ? 28 : 22,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Nuevo ícono de VoiceNotes.
          Container(
            padding: EdgeInsets.all(esAsistido ? 13 : 10),
            decoration: BoxDecoration(
              color: colores.principal,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: Colors.white,
              size: tamanoIcono,
            ),
          ),

          const SizedBox(width: 12),

          // Nombre y descripción.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VoiceNotes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tamanoTitulo,
                    fontWeight: FontWeight.w800,
                    color: colores.texto,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  esAsistido
                      ? 'Asistente de voz'
                      : 'Tu asistente personal',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: tamanoSubtitulo,
                    fontWeight: FontWeight.w600,
                    color: colores.texto,
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
