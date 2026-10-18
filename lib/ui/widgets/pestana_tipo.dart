import 'package:flutter/material.dart';

import '../themes/colores_perfil.dart';

/// Pestaña para cambiar entre ver "Notas" o "Recordatorios". Si se usa dentro de un Row, hay
/// que envolverla en un Expanded.
class PestanaTipo extends StatelessWidget {
  /// 'Nota' o 'Recordatorio'; también decide el texto de la pestaña.
  final String tipo;

  /// Ícono de la pestaña.
  final IconData icono;

  /// Si es la pestaña activa (se ve resaltada con el color principal).
  final bool seleccionada;

  /// Factor de tamaño de letras e íconos.
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Se llama al tocar la pestaña.
  final VoidCallback onTap;

  const PestanaTipo({
    super.key,
    required this.tipo,
    required this.icono,
    required this.seleccionada,
    required this.escala,
    required this.colores,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        // El cambio de color y sombra entre seleccionada y no seleccionada se anima suavemente.
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            vertical: 16 * escala,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            color: seleccionada
                ? colores.principal
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionada
                  ? colores.principal
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: seleccionada
                    ? colores.principal.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.025),
                blurRadius: seleccionada ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Ícono y nombre de la pestaña.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: 19 * escala,
                color: seleccionada
                    ? Colors.white
                    : colores.principal,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  tipo == 'Nota' ? 'Notas' : 'Recordatorios',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13 * escala,
                    fontWeight: seleccionada
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: seleccionada
                        ? Colors.white
                        : colores.texto,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
