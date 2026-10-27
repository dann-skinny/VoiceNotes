import 'package:flutter/material.dart';

import 'pantalla_principal.dart';

/// Primera pantalla de la app: la persona elige su perfil (Estudiante o Adulto Mayor /
/// Asistido). Al elegir uno se abre la pantalla principal con ese perfil.
class PantallaSeleccionPerfil extends StatelessWidget {
  const PantallaSeleccionPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        // LayoutBuilder y scroll: el contenido queda centrado en pantallas altas y se puede
        // desplazar en pantallas pequeñas.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo de la app.
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/icon/icono.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 18),

                    // Nombre y descripción de la app.
                    const Text(
                      'VoiceNotes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24243A),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Tu asistente personal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF77788D),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Título de la sección y su explicación.
                    const Text(
                      'Elige tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF24243A),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Selecciona cómo quieres utilizar la aplicación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF77788D),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Una tarjeta por cada perfil. Al tocarla se abre la pantalla principal con
                    // ese perfil.
                    _tarjeta(
                      context,
                      'Estudiante',
                      'Organiza tus notas, tareas y recordatorios.',
                      Icons.school_rounded,
                      const Color(0xFF7659E8),
                      'Estudiante',
                    ),

                    const SizedBox(height: 14),

                    _tarjeta(
                      context,
                      'Adulto Mayor / Asistido',
                      'Recordatorios, medicamentos y asistencia por voz.',
                      Icons.volunteer_activism_rounded,
                      const Color(0xFFC2410C),
                      'Adulto Mayor',
                    ),

                    const SizedBox(height: 38),

                    // Frase final de ayuda.
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_none_rounded,
                          color: Color(0xFF77788D),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Organiza tu día con tu voz',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF77788D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Tarjeta tocable para elegir un perfil. [titulo] y [subtitulo] son los textos, [icono] y
  /// [color] el estilo, y [perfil] el nombre interno que se le manda a la pantalla principal
  /// ('Estudiante' o 'Adulto Mayor').
  Widget _tarjeta(
    BuildContext context,
    String titulo,
    String subtitulo,
    IconData icono,
    Color color,
    String perfil,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // Al tocar, se abre la pantalla principal con el perfil elegido.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaPrincipal(
                perfilInicial: perfil,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // Ícono a la izquierda, textos en medio y una flechita a la derecha.
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icono,
                  size: 28,
                  color: color,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF24243A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF77788D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
