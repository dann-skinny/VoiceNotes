
import 'package:flutter/material.dart';

import '../../models/elemento_flow.dart';
import '../themes/colores_perfil.dart';

/// Tarjeta que muestra una nota o recordatorio.
/// Permite escucharlo, editarlo por voz o eliminarlo.
class TarjetaElemento extends StatelessWidget {
  final ElementoFlow item;
  final double escala;
  final ColoresPerfil colores;

  final VoidCallback alEscuchar;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const TarjetaElemento({
    super.key,
    required this.item,
    required this.escala,
    required this.colores,
    required this.alEscuchar,
    required this.alEditar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final recordatorio = item.tipo == 'Recordatorio';
    final asistido = colores.esAdultoMayor;

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
                        fontSize: asistido ? 22 : 14 * escala,
                        fontWeight: FontWeight.w700,
                        color: colores.texto,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      recordatorio ? 'Recordatorio' : 'Nota',
                      style: TextStyle(
                        fontSize: asistido ? 17 : 11 * escala,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

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

            if (item.fechaEvento != null)
              _detalleFechaElemento(
                icono: Icons.event_outlined,
                titulo: 'Fecha del evento',
                valor: _formatearFecha(item.fechaEvento!),
                color: colores.principal,
                escala: escala,
                asistido: asistido,
              ),

            if (item.fechaEvento != null &&
                item.fechaRecordatorio != null)
              const SizedBox(height: 12),

            if (item.fechaRecordatorio != null)
              _detalleFechaElemento(
                icono: Icons.notifications_active_outlined,
                titulo: 'Fecha y hora del aviso',
                valor: _formatearFecha(item.fechaRecordatorio!),
                color: colores.principal,
                escala: escala,
                asistido: asistido,
              ),

            if (item.avisoRelativo &&
                item.diasAnticipacion != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: colores.principal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.diasAnticipacion == 1
                      ? 'Aviso programado 1 día antes'
                      : 'Aviso programado ${item.diasAnticipacion} días antes',
                  style: TextStyle(
                    fontSize: asistido ? 16 : 10 * escala,
                    fontWeight: FontWeight.w600,
                    color: colores.principal,
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 14),
          Divider(
            color: Colors.black.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 8),

          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _botonAccion(
                icono: Icons.volume_up_outlined,
                etiqueta: 'Escuchar',
                color: colores.principal,
                fondo: colores.fondo,
                asistido: asistido,
                onPressed: alEscuchar,
              ),
              _botonAccion(
                icono: Icons.edit_outlined,
                etiqueta: 'Editar',
                color: colores.principal,
                fondo: colores.principal.withValues(alpha: 0.10),
                asistido: asistido,
                onPressed: alEditar,
              ),
              _botonAccion(
                icono: Icons.delete_outline_rounded,
                etiqueta: 'Eliminar',
                color: const Color(0xFFE05260),
                fondo: const Color(0xFFFFF1F2),
                asistido: asistido,
                onPressed: alEliminar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String etiqueta,
    required Color color,
    required Color fondo,
    required bool asistido,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: fondo,
        foregroundColor: color,
        minimumSize: Size(0, asistido ? 56 : 44),
        padding: EdgeInsets.symmetric(
          horizontal: asistido ? 14 : 10,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icono, size: asistido ? 25 : 20),
      label: Text(
        etiqueta,
        style: TextStyle(
          fontSize: asistido ? 17 : 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(fecha.year, fecha.month, fecha.day);

    String etiqueta;

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

  Widget _detalleFechaElemento({
    required IconData icono,
    required String titulo,
    required String valor,
    required double escala,
    required Color color,
    required bool asistido,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: asistido ? 24 : 16 * escala,
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
                  fontSize: asistido ? 16 : 10 * escala,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                softWrap: true,
                style: TextStyle(
                  fontSize: asistido ? 19 : 12 * escala,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
