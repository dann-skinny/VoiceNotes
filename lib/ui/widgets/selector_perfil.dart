import 'package:flutter/material.dart';

/// Panel "PERFIL ACTIVO" para cambiar de perfil: Estudiante o Asistido (Adulto Mayor).
class SelectorPerfil extends StatelessWidget {
  /// Perfil que está activo ahora.
  final String perfilActivo;

  /// Factor de tamaño de letras (más grande en modo asistido).
  final double escala;

  /// Se llama con el perfil elegido ('Estudiante' o 'Adulto Mayor').
  final void Function(String perfil) alCambiar;

  const SelectorPerfil({
    super.key,
    required this.perfilActivo,
    required this.escala,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del panel.
            Text(
              'PERFIL ACTIVO',
              style: TextStyle(
                fontSize: 11 * escala,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            // Las dos opciones de perfil, una al lado de la otra.
            Row(
              children: [
                Expanded(
                  child: _OpcionPerfil(
                      perfil: 'Estudiante',
                      seleccionado: perfilActivo == 'Estudiante',
                      escala: escala,
                      onTap: () => alCambiar('Estudiante'),
                    ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OpcionPerfil(
                      perfil: 'Adulto Mayor',
                      seleccionado: perfilActivo == 'Adulto Mayor',
                      escala: escala,
                      onTap: () => alCambiar('Adulto Mayor'),
                    ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Una de las dos opciones del selector. La opción seleccionada se ve con fondo blanco y letra
/// en negrita.
class _OpcionPerfil extends StatelessWidget {
  /// Perfil que representa esta opción.
  final String perfil;

  /// Si es el perfil activo.
  final bool seleccionado;

  /// Factor de tamaño de letras.
  final double escala;

  /// Se llama al tocar la opción.
  final VoidCallback onTap;

  const _OpcionPerfil({
    required this.perfil,
    required this.seleccionado,
    required this.escala,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        // El perfil 'Adulto Mayor' se muestra con el nombre "Asistido".
        child: Text(
          perfil == 'Adulto Mayor' ? 'Asistido' : 'Estudiante',
          style: TextStyle(
            fontSize: 11 * escala,
            fontWeight: seleccionado
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
