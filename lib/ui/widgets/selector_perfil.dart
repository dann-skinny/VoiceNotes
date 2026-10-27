
import 'package:flutter/material.dart';

/// Selector de perfiles de VoiceNotes.
class SelectorPerfil extends StatelessWidget {
  final String perfilActivo;
  final double escala;
  final void Function(String perfil) alCambiar;

  const SelectorPerfil({
    super.key,
    required this.perfilActivo,
    required this.escala,
    required this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    final esAsistido = perfilActivo == 'Adulto Mayor';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(esAsistido ? 18 : 14),
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
            Text(
              'PERFIL ACTIVO',
              style: TextStyle(
                fontSize: esAsistido ? 19 : 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _OpcionPerfil(
                    perfil: 'Estudiante',
                    seleccionado: perfilActivo == 'Estudiante',
                    esAsistido: esAsistido,
                    icono: Icons.school_rounded,
                    color: const Color(0xFF5269C7),
                    onTap: () => alCambiar('Estudiante'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _OpcionPerfil(
                    perfil: 'Adulto Mayor',
                    seleccionado: perfilActivo == 'Adulto Mayor',
                    esAsistido: esAsistido,
                    icono: Icons.accessibility_new_rounded,
                    color: const Color(0xFF008577),
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

/// Botón individual de selección de perfil.
class _OpcionPerfil extends StatelessWidget {
  final String perfil;
  final bool seleccionado;
  final bool esAsistido;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _OpcionPerfil({
    required this.perfil,
    required this.seleccionado,
    required this.esAsistido,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = perfil == 'Adulto Mayor'
        ? 'Asistido'
        : 'Estudiante';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            minHeight: esAsistido ? 105 : 84,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: esAsistido ? 6 : 8,
            vertical: esAsistido ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: seleccionado
                ? color.withValues(alpha: 0.12)
                : const Color(0xFFF5F6F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: seleccionado ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icono,
                size: esAsistido ? 38 : 30,
                color: color,
              ),

              const SizedBox(height: 8),

              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  nombre,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: esAsistido ? 21 : 15,
                    fontWeight: seleccionado
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: seleccionado
                        ? color
                        : Colors.black87,
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
