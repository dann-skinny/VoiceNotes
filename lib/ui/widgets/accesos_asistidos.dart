import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';
import 'boton_rapido.dart';

/// Accesos especiales del perfil Adulto Mayor: tomar medicamento, cita médica, llamar al
/// contacto de emergencia y configurarlo.
class AccesosAsistidos extends StatelessWidget {
  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Se llama al tocar "Tomar medicamento".
  final VoidCallback alTomarMedicamento;

  /// Se llama al tocar "Cita médica".
  final VoidCallback alCitaMedica;

  /// Se llama al tocar el botón de emergencia.
  final VoidCallback alLlamarEmergencia;

  /// Se llama al tocar "Configurar contacto".
  final VoidCallback alConfigurarContacto;

  const AccesosAsistidos({
    super.key,
    required this.escala,
    required this.colores,
    required this.alTomarMedicamento,
    required this.alCitaMedica,
    required this.alLlamarEmergencia,
    required this.alConfigurarContacto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Medicamento y cita médica, lado a lado y con la misma altura.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: BotonRapido(
                    icono: Icons.medication_rounded,
                    titulo: 'Tomar medicamento',
                    descripcion: 'Crear aviso',
                    accion: alTomarMedicamento,
                    escala: escala,
                    colores: colores,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BotonRapido(
                    icono: Icons.event_available_rounded,
                    titulo: 'Cita médica',
                    descripcion: 'Crear aviso',
                    accion: alCitaMedica,
                    escala: escala,
                    colores: colores,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Botón rojo de emergencia: llama al contacto registrado.
          BotonRapido(
            icono: Icons.phone_in_talk_rounded,
            titulo: 'Contacto de emergencia',
            descripcion: 'Llamar al contacto registrado',
            accion: alLlamarEmergencia,
            escala: escala,
            colores: colores,
            horizontal: true,
            emergencia: true,
            iconoFinal: Icons.arrow_outward_rounded,
          ),
          const SizedBox(height: 10),
          // Configurar o cambiar el número del contacto de emergencia.
          BotonRapido(
            icono: Icons.contact_phone_rounded,
            titulo: 'Configurar contacto',
            descripcion: 'Administrar número de emergencia',
            accion: alConfigurarContacto,
            escala: escala,
            colores: colores,
            horizontal: true,
          ),
        ],
      ),
    );
  }
}
