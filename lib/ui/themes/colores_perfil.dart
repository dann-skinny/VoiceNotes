import 'package:flutter/material.dart';

/// Colores de la pantalla según el perfil activo: naranja y fondo cálido para Adulto Mayor,
/// morado y fondo frío para Estudiante.
class ColoresPerfil {
  /// Es true cuando el perfil activo es 'Adulto Mayor'.
  final bool esAdultoMayor;

  const ColoresPerfil({required this.esAdultoMayor});

  /// Crea los colores a partir del nombre del perfil.
  factory ColoresPerfil.de(String perfil) {
    return ColoresPerfil(esAdultoMayor: perfil == 'Adulto Mayor');
  }

  /// Color principal: botones, íconos y acentos.
  Color get principal => esAdultoMayor
      ? const Color(0xFFC2410C)
      : const Color(0xFF7659E8);

  /// Color de fondo de la pantalla.
  Color get fondo => esAdultoMayor
      ? const Color(0xFFFFF9F5)
      : const Color(0xFFF8F9FC);

  /// Color de los textos importantes.
  Color get texto => esAdultoMayor
      ? const Color(0xFF292524)
      : const Color(0xFF24243A);
}
