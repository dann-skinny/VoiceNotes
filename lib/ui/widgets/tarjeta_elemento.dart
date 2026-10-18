import 'package:flutter/material.dart';

import '../../models/elemento_flow.dart';
import '../themes/colores_perfil.dart';

/// Tarjeta que dibuja una nota o un recordatorio en la lista: el texto, sus fechas (si es
/// recordatorio) y los botones para escucharlo o eliminarlo.
class TarjetaElemento extends StatelessWidget {
  /// La nota o el recordatorio que se muestra.
  final ElementoFlow item;

  /// Factor de tamaño de letras e íconos (más grande en modo asistido).
  final double escala;

  /// Colores del perfil activo.
  final ColoresPerfil colores;

  /// Se llama al tocar el botón de escuchar (lee el texto en voz alta).
  final VoidCallback alEscuchar;

  /// Se llama al tocar el botón de eliminar.
  final VoidCallback alEliminar;

  const TarjetaElemento({
    super.key,
    required this.item,
    required this.escala,
    required this.colores,
    required this.alEscuchar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    // Los recordatorios muestran información extra (fechas y anticipación).
    final recordatorio = item.tipo == 'Recordatorio';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16 * escala),
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
          // Encabezado: ícono del tipo, texto y etiqueta "Nota" o "Recordatorio".
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colores.principal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  recordatorio
                      ? Icons.notifications_none_rounded
                      : Icons.edit_note_rounded,
                  color: colores.principal,
                  size: 23 * escala,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.texto,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 14 * escala,
                        fontWeight: FontWeight.w700,
                        color: colores.texto,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      recordatorio ? 'Recordatorio' : 'Nota',
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

          // Información exclusiva de recordatorios: solo se muestra si hay alguna fecha que
          // enseñar.
          if (recordatorio &&
              (item.fechaEvento != null ||
                  item.fechaRecordatorio != null ||
                  (item.avisoRelativo &&
                      item.diasAnticipacion != null))) ...[
            const SizedBox(height: 14),
            Divider(
              color: Colors.black.withValues(alpha: 0.06),
            ),
            const SizedBox(height: 10),

            // Fecha del evento.
            if (item.fechaEvento != null)
              _detalleFechaElemento(
                icono: Icons.event_outlined,
                titulo: 'Fecha del evento',
                valor: _formatearFecha(item.fechaEvento!),
                escala: escala,
                color: colores.principal,
              ),

            if (item.fechaEvento != null &&
                item.fechaRecordatorio != null)
              const SizedBox(height: 12),

            // Fecha y hora en que sonará el aviso.
            if (item.fechaRecordatorio != null)
              _detalleFechaElemento(
                icono: Icons.notifications_active_outlined,
                titulo: 'Fecha y hora del aviso',
                valor: _formatearFecha(
                  item.fechaRecordatorio!,
                ),
                escala: escala,
                color: colores.principal,
              ),

            // Etiqueta que indica con cuántos días de anticipación se programó el aviso.
            if (item.avisoRelativo &&
                item.diasAnticipacion != null) ...[
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colores.principal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: colores.principal,
                      size: 15 * escala,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.diasAnticipacion == 1
                            ? 'Aviso programado 1 día antes'
                            : 'Aviso programado ${item.diasAnticipacion} días antes',
                        style: TextStyle(
                          fontSize: 10 * escala,
                          fontWeight: FontWeight.w600,
                          color: colores.principal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 14),

          Divider(
            color: Colors.black.withValues(alpha: 0.06),
          ),

          const SizedBox(height: 6),

          // Botones: escuchar el texto en voz alta y eliminar.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Escuchar',
                onPressed: alEscuchar,
                style: IconButton.styleFrom(
                  backgroundColor: colores.fondo,
                  foregroundColor: colores.principal,
                ),
                icon: const Icon(
                  Icons.volume_up_outlined,
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Eliminar',
                onPressed: alEliminar,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  foregroundColor: const Color(0xFFE05260),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Da formato amigable a una fecha: "Hoy · 09:30", "Mañana · 18:00" o "15/3/2027 · 08:00".
  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);

    String etiqueta;

    // Hoy y mañana se muestran con palabras; los demás días, con la fecha completa.
    if (dia == hoy) {
      etiqueta = 'Hoy';
    } else if (dia == hoy.add(const Duration(days: 1))) {
      etiqueta = 'Mañana';
    } else {
      etiqueta = '${fecha.day}/${fecha.month}/${fecha.year}';
    }

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$etiqueta · $hora:$minuto';
  }

  /// Una línea de detalle con ícono, un título pequeño y un valor (por ejemplo, "Fecha del
  /// evento" y su fecha).
  Widget _detalleFechaElemento({
    required IconData icono,
    required String titulo,
    required String valor,
    required double escala,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 16 * escala,
          color: color,
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 10 * escala,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                valor,
                softWrap: true,
                style: TextStyle(
                  fontSize: 12 * escala,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
