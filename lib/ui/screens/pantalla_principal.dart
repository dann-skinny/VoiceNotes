import 'package:flutter/material.dart';

import '../../controllers/lifeflow_controller.dart';
import '../../models/elemento_flow.dart';
import '../dialogs/dialogo_aclaracion.dart';
import '../dialogs/dialogo_alerta.dart';
import '../dialogs/dialogo_confirmar_llamada.dart';
import '../dialogs/dialogo_numero_emergencia.dart';
import '../themes/colores_perfil.dart';
import '../widgets/accesos_asistidos.dart';
import '../widgets/area_dictado.dart';
import '../widgets/boton_microfono.dart';
import '../widgets/encabezado_lifeflow.dart';
import '../widgets/encabezado_lista.dart';
import '../widgets/estado_vacio.dart';
import '../widgets/pestana_tipo.dart';
import '../widgets/selector_perfil.dart';
import '../widgets/tarjeta_elemento.dart';

/// Pantalla principal de la app: aquí se dictan, se ven y se administran las notas y los
/// recordatorios. Es solo la parte visual; la lógica está en [LifeFlowController].
class PantallaPrincipal extends StatefulWidget {
  /// Perfil con el que se abre la pantalla ('Estudiante' o 'Adulto Mayor'), elegido en la
  /// pantalla anterior.
  final String perfilInicial;

  const PantallaPrincipal({
    super.key,
    required this.perfilInicial,
  });

  /// Se conecta al controlador, le entrega las tres funciones que necesita de la pantalla
  /// (mostrar mensajes, lanzar alertas y hacer preguntas) y carga los datos guardados.
  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

/// Estado de la pantalla: se conecta al controlador, atiende lo que este le pide (mensajes,
/// alertas y preguntas) y arma la interfaz con los widgets.
class _PantallaPrincipalState extends State<PantallaPrincipal> {
  /// Controlador con la lógica de la app (guardar, dictar, avisar...).
  late final LifeFlowController _c;

  // Atajos para leer el estado del controlador desde esta pantalla.
  List<ElementoFlow> get _elementos => _c.elementos;
  String get _textoDictado => _c.textoDictado;
  String get _numeroEmergencia => _c.numeroEmergencia;
  bool get _estaEscuchando => _c.estaEscuchando;
  bool get _finalizando => _c.finalizando;
  bool get _cargando => _c.cargando;

  // Estos tres valores también se pueden cambiar desde la pantalla (siempre dentro de un
  // setState).
  String get _perfilActivo => _c.perfilActivo;
  set _perfilActivo(String valor) => _c.perfilActivo = valor;

  String get _tipoActual => _c.tipoActual;
  set _tipoActual(String valor) => _c.tipoActual = valor;

  DateTime? get _horaSeleccionada => _c.horaSeleccionada;
  set _horaSeleccionada(DateTime? valor) => _c.horaSeleccionada = valor;

  /// Colores según el perfil activo.
  ColoresPerfil get _colores => ColoresPerfil.de(_perfilActivo);

  // Atajos a las acciones del controlador que usa la interfaz.
  Future<void> _reproducirVoz(String mensaje) => _c.hablar(mensaje);
  Future<void> _toggleEscuchaVoz() => _c.toggleEscuchaVoz();
  Future<void> _eliminarElemento(ElementoFlow item) =>
      _c.eliminarElemento(item);

  /// Al salir de la pantalla deja de escuchar al controlador y lo cierra.
  @override
  void initState() {
    super.initState();

    _c = LifeFlowController(perfilInicial: widget.perfilInicial)
      ..alMostrarMensaje = _mostrarMensaje
      ..alLanzarAlerta = _lanzarAlerta
      ..alSolicitarAclaracion = _solicitarAclaracion;

    _c.addListener(_refrescar);
    _c.iniciar();
  }

  /// Arma la pantalla completa. Cada bloque visual es un widget aparte.
  @override
  void dispose() {
    _c.removeListener(_refrescar);
    _c.dispose();
    super.dispose();
  }

  /// Redibuja la pantalla cuando el controlador avisa que algo cambió.
  void _refrescar() {
    if (mounted) setState(() {});
  }

  /// Muestra un avisito flotante (SnackBar) en la parte baja de la pantalla.
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  /// Llegó la hora de un recordatorio: se lee en voz alta y se abre la alerta en pantalla.
  void _lanzarAlerta(ElementoFlow item) {
    if (!mounted) return;

    // El título de la alerta cambia según el perfil.
    final titulo = item.perfil == 'Adulto Mayor'
        ? 'Recordatorio importante'
        : 'Recordatorio pendiente';

    // Se lee en voz alta el título y el texto del recordatorio.
    _reproducirVoz('$titulo: ${item.texto}');

    // La alerta usa los colores del perfil dueño del recordatorio. Al tocar "Entendido" se calla la voz.
    mostrarDialogoAlerta(
      context,  
      titulo: titulo,
      mensaje: item.texto,
      colores: ColoresPerfil.de(item.perfil),
      alEntendido: () => _c.detenerHabla(),
    );
  }

  /// El controlador necesita aclarar algo: se lee la pregunta en voz alta y se muestra un
  /// diálogo con opciones. Devuelve la opción elegida (o null si la persona cancela).
  Future<String?> _solicitarAclaracion({
    required String pregunta,
    required List<String> opciones,
  }) async {
    if (!mounted) return null;

    await _reproducirVoz(pregunta);
    if (!mounted) return null;

    return mostrarDialogoAclaracion(
      context,
      pregunta: pregunta,
      opciones: opciones,
      colores: _colores,
    );
  }

  /// Pide el número del contacto de emergencia y, si la persona lo escribe, lo manda a guardar.
  Future<void> _configurarNumeroEmergencia() async {
    final numero = await mostrarDialogoNumeroEmergencia(
      context,
      numeroActual: _numeroEmergencia,
    );

    if (!mounted || numero == null) return;

    await _c.guardarNumeroEmergencia(numero);
  }

  /// Llama al contacto de emergencia. Si no hay número guardado, primero se pide; si lo hay, se
  /// pide confirmación antes de llamar.
  Future<void> _hacerLlamadaEmergencia() async {
    // Sin número guardado no se puede llamar: se pide primero.
    if (_numeroEmergencia.isEmpty) {
      await _configurarNumeroEmergencia();
      return;
    }

    // Confirmación para evitar llamadas por accidente.
    final confirmar = await mostrarDialogoConfirmarLlamada(
      context,
      numero: _numeroEmergencia,
    );

    if (confirmar != true || !mounted) return;

    await _c.llamarEmergencia();
  }

  /// Abre el selector de hora y guarda la hora elegida (con la fecha de hoy).
  Future<void> _elegirHora() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (seleccion == null || !mounted) return;

    final ahora = DateTime.now();

    setState(() {
      _horaSeleccionada = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        seleccion.hour,
        seleccion.minute,
      );
    });
  }

  /// Acceso rápido del modo asistido: cambia a la pestaña de recordatorios y dice en voz alta
  /// qué debe dictar la persona.
  void _prepararRecordatorio(String instruccion) {
    setState(() {
      _tipoActual = 'Recordatorio';
    });

    _reproducirVoz(instruccion);
  }

  @override
  Widget build(BuildContext context) {
    // Colores y tamaño de letra según el perfil: en modo asistido todo se ve 20 % más grande.
    final colores = _colores;
    final escala = colores.esAdultoMayor ? 1.2 : 1.0;

    // Solo se muestran los elementos del perfil y de la pestaña actuales.
    final filtrados = _elementos.where((item) {
      return item.perfil == _perfilActivo &&
          item.tipo == _tipoActual;
    }).toList();

    return Scaffold(
      backgroundColor: colores.fondo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Parte de arriba: encabezado, perfiles, accesos, pestañas y área de dictado.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  EncabezadoLifeFlow(
                    escala: escala,
                    colores: colores,
                  ),

                  // Cambiar de perfil al vuelo.
                  SelectorPerfil(
                    perfilActivo: _perfilActivo,
                    escala: escala,
                    alCambiar: (perfil) {
                      setState(() {
                        _perfilActivo = perfil;
                      });
                    },
                  ),

                  // Accesos especiales que solo ve el perfil Adulto Mayor.
                  if (colores.esAdultoMayor)
                    AccesosAsistidos(
                      escala: escala,
                      colores: colores,
                      alTomarMedicamento: () => _prepararRecordatorio(
                        'Dicta el medicamento y la hora',
                      ),
                      alCitaMedica: () => _prepararRecordatorio(
                        'Dicta la fecha y hora de tu cita',
                      ),
                      alLlamarEmergencia: _hacerLlamadaEmergencia,
                      alConfigurarContacto: _configurarNumeroEmergencia,
                    ),

                  // Pestañas para elegir entre notas y recordatorios.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: PestanaTipo(
                            tipo: 'Nota',
                            icono: Icons.edit_note_rounded,
                            seleccionada: _tipoActual == 'Nota',
                            escala: escala,
                            colores: colores,
                            onTap: () {
                              setState(() {
                                _tipoActual = 'Nota';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: PestanaTipo(
                            tipo: 'Recordatorio',
                            icono: Icons.notifications_none_rounded,
                            seleccionada: _tipoActual == 'Recordatorio',
                            escala: escala,
                            colores: colores,
                            onTap: () {
                              setState(() {
                                _tipoActual = 'Recordatorio';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Texto dictado y selector de hora.
                  AreaDictado(
                    escala: escala,
                    colores: colores,
                    estaEscuchando: _estaEscuchando,
                    textoDictado: _textoDictado,
                    tipoActual: _tipoActual,
                    horaSeleccionada: _horaSeleccionada,
                    alElegirHora: _elegirHora,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Título de la lista y cuántos elementos hay.
            SliverToBoxAdapter(
              child: EncabezadoLista(
                tipoActual: _tipoActual,
                cantidad: filtrados.length,
                escala: escala,
                colores: colores,
              ),
            ),

            // La lista tiene tres estados: cargando, vacía o con elementos.
            if (_cargando)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filtrados.isEmpty)
              SliverToBoxAdapter(
                child: EstadoVacio(
                  tipoActual: _tipoActual,
                  escala: escala,
                  colores: colores,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, indice) {
                    final item = filtrados[indice];

                    return TarjetaElemento(
                      item: item,
                      escala: escala,
                      colores: colores,
                      alEscuchar: () => _reproducirVoz(item.texto),
                      alEliminar: () => _eliminarElemento(item),
                    );
                  },
                ),
              ),

            // Espacio al final para que el botón del micrófono no tape el último elemento.
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),

      // Micrófono fijo en la parte inferior de la pantalla.
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,

      floatingActionButton: BotonMicrofono(
        estaEscuchando: _estaEscuchando,
        deshabilitado: _cargando || _finalizando,
        colores: colores,
        alPresionar: _toggleEscuchaVoz,
      ),
    );
  }
}
