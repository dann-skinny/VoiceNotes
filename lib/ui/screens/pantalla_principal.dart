
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

/// Pantalla principal de VoiceNotes.
/// La lógica de la aplicación se encuentra en LifeFlowController.
class PantallaPrincipal extends StatefulWidget {
  final String perfilInicial;

  const PantallaPrincipal({
    super.key,
    required this.perfilInicial,
  });

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late final LifeFlowController _c;

  String _busqueda = '';

  List<ElementoFlow> get _elementos => _c.elementos;
  String get _textoDictado => _c.textoDictado;
  String get _numeroEmergencia => _c.numeroEmergencia;
  bool get _estaEscuchando => _c.estaEscuchando;
  bool get _finalizando => _c.finalizando;
  bool get _cargando => _c.cargando;

  String get _perfilActivo => _c.perfilActivo;
  set _perfilActivo(String valor) => _c.perfilActivo = valor;

  String get _tipoActual => _c.tipoActual;
  set _tipoActual(String valor) => _c.tipoActual = valor;

  DateTime? get _horaSeleccionada => _c.horaSeleccionada;
  set _horaSeleccionada(DateTime? valor) =>
      _c.horaSeleccionada = valor;

  ColoresPerfil get _colores => ColoresPerfil.de(_perfilActivo);

  Future<void> _reproducirVoz(String mensaje) => _c.hablar(mensaje);

  Future<void> _toggleEscuchaVoz() => _c.toggleEscuchaVoz();

  Future<void> _eliminarElemento(ElementoFlow item) =>
      _c.eliminarElemento(item);

  /// Permite editar una nota o recordatorio mediante la voz.
  /// El micrófono permanece apagado hasta que el usuario lo presiona.
  Future<void> _editarElemento(ElementoFlow item) async {
    if (_estaEscuchando || _finalizando || _cargando) {
      _mostrarMensaje('Termina el dictado antes de editar.');
      return;
    }

    final destino = item.tipo == 'Recordatorio'
        ? await _solicitarAclaracion(
            pregunta: '¿Qué quieres modificar?',
            opciones: ['Nombre', 'Evento', 'Aviso', 'Ambas'],
          )
        : await _solicitarAclaracion(
            pregunta: '¿Quieres modificar el contenido de esta nota?',
            opciones: ['Modificar nota'],
          );

    if (!mounted || destino == null) return;

    await _c.iniciarEdicionPorVoz(
      item,
      destino: item.tipo == 'Nota' ? 'Nota' : destino,
    );
  }

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

  @override
  void dispose() {
    _c.removeListener(_refrescar);
    _c.dispose();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Muestra mensajes informativos.
  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
      ),
    );
  }

  /// Muestra la alerta de un recordatorio.
  void _lanzarAlerta(ElementoFlow item) {
    if (!mounted) return;

    final titulo = item.perfil == 'Adulto Mayor'
        ? 'Recordatorio importante'
        : 'Recordatorio pendiente';

    _reproducirVoz('$titulo: ${item.texto}');

    mostrarDialogoAlerta(
      context,
      titulo: titulo,
      mensaje: item.texto,
      colores: ColoresPerfil.de(item.perfil),
      alEntendido: () => _c.detenerHabla(),
    );
  }

  /// Solicita aclaraciones mediante el diálogo original.
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

  /// Configura el número de emergencia.
  Future<void> _configurarNumeroEmergencia() async {
    final numero = await mostrarDialogoNumeroEmergencia(
      context,
      numeroActual: _numeroEmergencia,
    );

    if (!mounted || numero == null) return;

    await _c.guardarNumeroEmergencia(numero);
  }

  /// Realiza la llamada de emergencia.
  Future<void> _hacerLlamadaEmergencia() async {
    if (_numeroEmergencia.isEmpty) {
      await _configurarNumeroEmergencia();
      return;
    }

    final confirmar = await mostrarDialogoConfirmarLlamada(
      context,
      numero: _numeroEmergencia,
    );

    if (confirmar != true || !mounted) return;

    await _c.llamarEmergencia();
  }

  /// Permite seleccionar la hora de un recordatorio.
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

  /// Prepara un recordatorio desde el modo asistido.
  void _prepararRecordatorio(String instruccion) {
    setState(() {
      _tipoActual = 'Recordatorio';
    });

    _reproducirVoz(instruccion);
  }

  @override
  Widget build(BuildContext context) {
    final colores = _colores;
    final escala = colores.esAdultoMayor ? 1.2 : 1.0;

    // Filtrar notas y recordatorios.
    final consulta = _busqueda.trim().toLowerCase();

    final filtrados = _elementos.where((item) {
      return item.perfil == _perfilActivo &&
          item.tipo == _tipoActual &&
          item.texto.toLowerCase().contains(consulta);
    }).toList();

    return Scaffold(
      backgroundColor: colores.fondo,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Encabezado original.
                  EncabezadoLifeFlow(
                    escala: escala,
                    colores: colores,
                  ),

                  // Selector de perfiles original.
                  SelectorPerfil(
                    perfilActivo: _perfilActivo,
                    escala: escala,
                    alCambiar: (perfil) {
                      setState(() {
                        _perfilActivo = perfil;
                      });
                    },
                  ),

                  // Accesos del modo Adulto Mayor.
                  if (colores.esAdultoMayor)
                    AccesosAsistidos(
                      escala: escala,
                      colores: colores,
                      alTomarMedicamento: () =>
                          _prepararRecordatorio(
                        'Dicta el medicamento y la hora',
                      ),
                      alCitaMedica: () => _prepararRecordatorio(
                        'Dicta la fecha y hora de tu cita',
                      ),
                      alLlamarEmergencia: _hacerLlamadaEmergencia,
                      alConfigurarContacto:
                          _configurarNumeroEmergencia,
                    ),

                  // Pestañas originales.
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                            seleccionada:
                                _tipoActual == 'Recordatorio',
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

                  // Barra de búsqueda.
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: TextField(
                      onChanged: (valor) {
                        setState(() {
                          _busqueda = valor;
                        });
                      },
                      textInputAction: TextInputAction.search,
                      style: TextStyle(
                        fontSize: 16 * escala,
                      ),
                      decoration: InputDecoration(
                        hintText: _tipoActual == 'Nota'
                            ? 'Buscar notas...'
                            : 'Buscar recordatorios...',
                        prefixIcon:
                            const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surface,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Cancelación visible solo durante la edición.
                  if (_c.editandoPorVoz)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Editando: ${_c.destinoEdicion ?? 'elemento'}',
                              style: TextStyle(
                                fontSize: 13 * escala,
                                color: colores.texto,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _estaEscuchando || _finalizando
                                    ? null
                                    : _c.cancelarEdicionPorVoz,
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ),

                  // Área de dictado original.
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

            // Encabezado de la lista.
            SliverToBoxAdapter(
              child: EncabezadoLista(
                tipoActual: _tipoActual,
                cantidad: filtrados.length,
                escala: escala,
                colores: colores,
              ),
            ),

            // Estado de carga.
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, indice) {
                    final item = filtrados[indice];

                    return TarjetaElemento(
                      item: item,
                      escala: escala,
                      colores: colores,
                      alEscuchar: () =>
                          _reproducirVoz(item.texto),
                      alEditar: () => _editarElemento(item),
                      alEliminar: () =>
                          _eliminarElemento(item),
                    );
                  },
                ),
              ),

            // Espacio para el botón flotante.
            const SliverToBoxAdapter(
              child: SizedBox(height: 110),
            ),
          ],
        ),
      ),

      // Micrófono original.
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
