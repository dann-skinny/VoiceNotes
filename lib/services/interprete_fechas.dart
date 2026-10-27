/// Entiende fechas, horas y órdenes de cambio a partir del texto dictado. Son funciones puras:
/// no usan pantallas, ni voz, ni la memoria del celular.
class InterpreteFechas {
  /// Entiende lo que la persona dijo al dictar un recordatorio y devuelve cuándo es el evento,
  /// cuándo debe sonar el aviso y el texto ya limpio.
  ///
  /// Reconoce fechas ("15 de marzo"), días de la semana ("el viernes", "próximo lunes"),
  /// "mañana", anticipación ("2 días antes") y horas ("a las 5 de la tarde"). Lo que reconoce
  /// lo quita del texto, así el recordatorio queda solo con la actividad.
  ///
  /// [horaSeleccionada] es la hora elegida a mano; solo se usa si en el dictado no dijo ninguna
  /// hora.
  ///
  /// Devuelve un mapa con: fechaEvento, fechaRecordatorio, texto y diasAnticipacion.
  static Map<String, dynamic> procesarDictadoRecordatorio(
    String textoOriginal, {
    DateTime? horaSeleccionada,
  }) {
    final ahora = DateTime.now();
    String texto = textoOriginal.trim();

    // Se extrae la recurrencia antes de interpretar fechas u horas.
    // Así "cada 8 horas" no se confunde con una hora del reloj.
    final recurrencia = interpretarRecurrencia(texto);
    if (recurrencia['esRecurrente'] == true) {
      texto = recurrencia['textoSinRecurrencia'] as String;
    }

    // Fecha de partida: hoy a medianoche. Cambia si la persona dice otra fecha.
    DateTime fechaBase = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
    );

    // Recuerdan qué dijo la persona de verdad (fecha, hora) y cuántos días antes quiere el
    // aviso.
    bool fechaExplicita = false;
    bool horaExplicita = false;
    int diasAnticipacion = 0;

    // 1. Fecha con día y mes ("15 de marzo")
    // Nombres de los meses y su número.
    final meses = <String, int>{
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };

    // Busca el patrón "número + de + mes".
    final fechaRegex = RegExp(
      r'\b(\d{1,2})\s+de\s+'
      r'(enero|febrero|marzo|abril|mayo|junio|julio|'
      r'agosto|septiembre|setiembre|octubre|noviembre|diciembre)\b',
      caseSensitive: false,
    );

    final coincidenciaFecha = fechaRegex.firstMatch(texto);

    // Si encontró una fecha, se usa este año; si ya pasó, se usa el año siguiente.
    if (coincidenciaFecha != null) {
      final dia = int.parse(coincidenciaFecha.group(1)!);
      final mes = meses[coincidenciaFecha.group(2)!.toLowerCase()]!;

      var candidata = DateTime(ahora.year, mes, dia);

      // Se verifica que la fecha exista (el 31 de febrero, por ejemplo, no existe).
      if (candidata.month == mes && candidata.day == dia) {
        // Si esa fecha ya pasó este año, se pasa al año siguiente.
        if (candidata.isBefore(fechaBase)) {
          candidata = DateTime(ahora.year + 1, mes, dia);
        }

        // Se vuelve a verificar con el año nuevo (por ejemplo, el 29 de febrero).
        if (candidata.month == mes && candidata.day == dia) {
          fechaBase = candidata;
          fechaExplicita = true;

          // Se quita la fecha del texto para que quede solo la actividad.
          texto = texto.replaceFirst(fechaRegex, '').trim();
        }
      }
    }

    // 2. Día de la semana ("el viernes", "próximo lunes") 
    // Solo se busca si no dijo una fecha con día y mes.
    if (!fechaExplicita) {
      // Días de la semana y su número en Dart (lunes = 1 ... domingo = 7).
      final diasSemana = <String, int>{
        'lunes': DateTime.monday,
        'martes': DateTime.tuesday,
        'miércoles': DateTime.wednesday,
        'miercoles': DateTime.wednesday,
        'jueves': DateTime.thursday,
        'viernes': DateTime.friday,
        'sábado': DateTime.saturday,
        'sabado': DateTime.saturday,
        'domingo': DateTime.sunday,
      };

      // Detecta el día con su palabra opcional: "el", "este" o "próximo".
      final diaRegex = RegExp(
        r'\b(?:(el|este|próximo|proximo)\s+)?'
        r'(lunes|martes|miércoles|miercoles|jueves|'
        r'viernes|sábado|sabado|domingo)\b',
        caseSensitive: false,
      );

      final coincidenciaDia = diaRegex.firstMatch(texto);

      if (coincidenciaDia != null) {
        final nombreDia =
            coincidenciaDia.group(2)!.toLowerCase();

        final diaObjetivo = diasSemana[nombreDia]!;

        // Cuántos días faltan para el próximo día pedido (0 si es hoy).
        int diferencia =
            (diaObjetivo - ahora.weekday + 7) % 7;

        final modificador =
            coincidenciaDia.group(1)?.toLowerCase() ?? '';

        // "Próximo" siempre apunta a la semana que viene, aunque hoy sea ese día.
        if (modificador == 'próximo' ||
            modificador == 'proximo') {
          diferencia = diferencia == 0
              ? 7
              : diferencia + 7;
        }

        fechaBase = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + diferencia,
        );

        fechaExplicita = true;

        texto = texto.replaceFirst(diaRegex, '').trim();
      }
    }

    // 3. "Mañana" o "día siguiente" 
    if (!fechaExplicita) {
      final mananaRegex = RegExp(
        r'\b(mañana|día siguiente)\b',
        caseSensitive: false,
      );

      if (mananaRegex.hasMatch(texto)) {
        fechaBase = DateTime(
          ahora.year,
          ahora.month,
          ahora.day + 1,
        );

        fechaExplicita = true;
        texto = texto.replaceFirst(mananaRegex, '').trim();
      }
    }

    // 4. Anticipación ("2 días antes", "avísame tres días antes")
    final anticipacionRegex = RegExp(
      r'\b(?:avísame|avisame|recuérdame|recuerdame)?'
      r'\s*(?:con\s+)?'
      r'(un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|\d+)\s+días?\s+antes\b',
      caseSensitive: false,
    );

    final coincidenciaAnticipacion =
        anticipacionRegex.firstMatch(texto);

    if (coincidenciaAnticipacion != null) {
      final cantidad =
          coincidenciaAnticipacion.group(1)!.toLowerCase();

      // Números escritos con letras (hasta siete) para entender "dos días antes".
      final numeros = <String, int>{
        'un': 1,
        'uno': 1,
        'una': 1,
        'dos': 2,
        'tres': 3,
        'cuatro': 4,
        'cinco': 5,
        'seis': 6,
        'siete': 7,
      };

      diasAnticipacion =
          numeros[cantidad] ?? int.tryParse(cantidad) ?? 0;

      texto = texto
          .replaceFirst(anticipacionRegex, '')
          .trim();
    }

    // 5. Hora ("a las 5", "a las 3:30 pm", "a las 8 y media") 
    // Si no dice hora, se usan las 9:00 de la mañana.
    int hora = 9;
    int minuto = 0;

    // Detecta "a las X" o "las X", con minutos (3:30, "y media", "y cuarto") y momento del día
    // ("de la tarde", "pm", etc.).
    final horaRegex = RegExp(
      r'\b(?:a\s+las?\s+|las\s+)'
      r'(\d{1,2}|una|uno|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|once|doce)'
      r'(?::(\d{2})|\s+y\s+(media|cuarto))?'
      r'\s*(am|pm|a\.m|p\.m|a\.m\.|p\.m\.|'
      r'de la mañana|de la tarde|de la noche|'
      r'del mediodía|de la madrugada)?',
      caseSensitive: false,
    );

    final coincidenciaHora = horaRegex.firstMatch(texto);

    // Si encontró una hora, se convierte a formato de 24 horas.
    if (coincidenciaHora != null) {
      // Horas escritas con letras.
      const numeros = <String, int>{
        'una': 1,
        'uno': 1,
        'dos': 2,
        'tres': 3,
        'cuatro': 4,
        'cinco': 5,
        'seis': 6,
        'siete': 7,
        'ocho': 8,
        'nueve': 9,
        'diez': 10,
        'once': 11,
        'doce': 12,
      };

      final valorHora = coincidenciaHora.group(1)!.toLowerCase();

      // h = hora, m = minutos. Acepta números ("5") o palabras ("cinco").
      int? h = int.tryParse(valorHora) ?? numeros[valorHora];
      int m = int.tryParse(coincidenciaHora.group(2) ?? '') ?? 0;

      final fraccion = coincidenciaHora.group(3)?.toLowerCase();
      final periodo = (coincidenciaHora.group(4) ?? '').toLowerCase();

      // "Y media" son 30 minutos y "y cuarto" son 15.
      if (fraccion == 'media') {
        m = 30;
      } else if (fraccion == 'cuarto') {
        m = 15;
      }

      // Solo se acepta si la hora tiene sentido.
      if (h != null && h >= 1 && h <= 23 && m <= 59) {
        bool valida = true;

        // Se ajusta según el momento del día que dijo:
        // - tarde o noche: suma 12 horas.
        // - mañana o madrugada: las 12 pasan a ser las 0.
        // - mediodía: solo vale con las 12.
        // - si no dijo nada y la hora es menor a 7, se asume la tarde ("a las 5" = 17:00).
        if (periodo.contains('pm') ||
            periodo.contains('p.m') ||
            periodo.contains('p.m.') ||
            periodo.contains('tarde') ||
            periodo.contains('noche')) {
          if (h > 12) {
            valida = false;
          } else if (h < 12) {
            h += 12;
          }
        } else if (periodo.contains('am') ||
            periodo.contains('a.m') ||
            periodo.contains('a.m.') ||
            periodo.contains('mañana') ||
            periodo.contains('madrugada')) {
          if (h > 12) {
            valida = false;
          } else if (h == 12) {
            h = 0;
          }
        } else if (periodo.contains('mediodía')) {
          if (h != 12) valida = false;
        } else if (h < 7) {
          h += 12;
        }

        // Hora aceptada: se guarda y se quita del texto.
        if (valida) {
          hora = h;
          minuto = m;
          horaExplicita = true;

          // Se quitan del texto las palabras de relleno ("para el", "avísame"...) y los
          // espacios sobrantes.
          texto = texto.replaceFirst(horaRegex, '').trim();
        }
      }
    }

    //  6. Armar las fechas finales 
    // Si no dijo hora pero eligió una a mano, se usa esa.
    final horaFinal =
      horaSeleccionada != null && !horaExplicita
          ? horaSeleccionada.hour
          : hora;

    final minutoFinal =
      horaSeleccionada != null && !horaExplicita
          ? horaSeleccionada.minute
          : minuto;

    // Momento del evento: la fecha de partida con la hora final.
    DateTime fechaEvento = DateTime(
      fechaBase.year,
      fechaBase.month,
      fechaBase.day,
      horaFinal,
      minutoFinal,
    );

    final esRecurrente = recurrencia['esRecurrente'] == true;
    final inicioAutomatico = esRecurrente &&
        !horaExplicita && horaSeleccionada == null && !fechaExplicita;

    // Una repetición por intervalo sin hora indicada empieza a contar ahora.
    // La primera notificación se calcula más abajo: no se avisa de inmediato.
    if (inicioAutomatico) {
      fechaEvento = ahora;
    } else if (!fechaExplicita && fechaEvento.isBefore(ahora)) {
      fechaEvento = DateTime(
        fechaBase.year, fechaBase.month, fechaBase.day + 1,
        horaFinal, minutoFinal,
      );
    }

    // Para una recurrencia semanal, se calcula la primera fecha del día indicado.
    if (recurrencia['esRecurrente'] == true &&
        recurrencia['tipoRecurrencia'] == 'dias_semana' &&
        !fechaExplicita) {
      final dias = recurrencia['diasSemanaRecurrencia'] as List<int>;
      if (dias.isNotEmpty) {
        DateTime? siguiente;
        for (final dia in dias) {
          var diferencia = (dia - ahora.weekday + 7) % 7;
          var candidato = DateTime(ahora.year, ahora.month,
              ahora.day + diferencia,
              inicioAutomatico ? ahora.hour : horaFinal,
              inicioAutomatico ? ahora.minute : minutoFinal);
          if (!candidato.isAfter(ahora)) {
            candidato = DateTime(ahora.year, ahora.month,
                ahora.day + diferencia + 7,
                inicioAutomatico ? ahora.hour : horaFinal,
                inicioAutomatico ? ahora.minute : minutoFinal);
          }
          if (siguiente == null || candidato.isBefore(siguiente)) {
            siguiente = candidato;
          }
        }
        if (siguiente != null) fechaEvento = siguiente;
      }
    }

    // "El día 5 de cada mes" conserva el día del mes indicado.
    if (recurrencia['esRecurrente'] == true &&
        recurrencia['diaMesRecurrencia'] != null && !fechaExplicita) {
      final dia = recurrencia['diaMesRecurrencia'] as int;
      var candidato = DateTime(ahora.year, ahora.month, dia,
          horaFinal, minutoFinal);
      if (!candidato.isAfter(ahora)) {
        candidato = DateTime(ahora.year, ahora.month + 1, dia,
            horaFinal, minutoFinal);
      }
      // Los días 29, 30 y 31 pueden no existir en todos los meses.
      while (candidato.day != dia) {
        candidato = DateTime(candidato.year, candidato.month + 1,
            dia, horaFinal, minutoFinal);
      }
      fechaEvento = candidato;
    }

    // Para intervalos sin hora, el momento de creación es el inicio del ciclo.
    // Ejemplo: a las 18:00, cada 8 horas => primer aviso a las 02:00.
    DateTime fechaRecordatorio;
    if (inicioAutomatico &&
        recurrencia['tipoRecurrencia'] != 'dias_semana' &&
        recurrencia['diaMesRecurrencia'] == null) {
      final intervalo = recurrencia['intervaloRecurrencia'] as int? ?? 1;
      switch (recurrencia['tipoRecurrencia']) {
        case 'minutos':
          fechaRecordatorio = ahora.add(Duration(minutes: intervalo));
          break;
        case 'horas':
          fechaRecordatorio = ahora.add(Duration(hours: intervalo));
          break;
        case 'dias':
          fechaRecordatorio = ahora.add(Duration(days: intervalo));
          break;
        case 'semanas':
          fechaRecordatorio = ahora.add(Duration(days: 7 * intervalo));
          break;
        case 'meses':
        case 'anios':
          final meses = recurrencia['tipoRecurrencia'] == 'meses'
              ? intervalo : 12 * intervalo;
          final mesDestino = DateTime(ahora.year, ahora.month + meses, 1);
          final ultimoDia = DateTime(mesDestino.year, mesDestino.month + 1, 0).day;
          final dia = ahora.day <= ultimoDia ? ahora.day : ultimoDia;
          fechaRecordatorio = DateTime(mesDestino.year, mesDestino.month,
              dia, ahora.hour, ahora.minute, ahora.second);
          break;
        default:
          fechaRecordatorio = fechaEvento;
      }
    } else {
      fechaRecordatorio = DateTime(
        fechaEvento.year, fechaEvento.month,
        fechaEvento.day - diasAnticipacion,
        fechaEvento.hour, fechaEvento.minute,
        fechaEvento.second,
      );
    }

    texto = texto
      .replaceAll(
        RegExp(
          r'\b(para el|a las|a la|pero|avísame|avisame|'
          r'recuérdame|recuerdame)\b',
          caseSensitive: false,
        ),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

    // Si no quedó nada de texto, se usa el original completo.
    if (texto.isEmpty) {
      texto = textoOriginal.trim();
    }

    return {
      'fechaEvento': fechaEvento,
      'fechaRecordatorio': fechaRecordatorio,
      'texto': texto,
      'diasAnticipacion': diasAnticipacion,
      'esRecurrente': recurrencia['esRecurrente'],
      'tipoRecurrencia': recurrencia['tipoRecurrencia'],
      'intervaloRecurrencia': recurrencia['intervaloRecurrencia'],
      'diasSemanaRecurrencia': recurrencia['diasSemanaRecurrencia'],
      'diaMesRecurrencia': recurrencia['diaMesRecurrencia'],
      'fechaFinRecurrencia': calcularFinRecurrencia(
        recurrencia, inicioAutomatico ? ahora : fechaEvento),
      'fechaProximaRepeticion': recurrencia['esRecurrente'] == true
          ? fechaRecordatorio
          : null,
      'recurrenciaActiva': true,
      // La hora de inicio es automática cuando no se especifica.
      'requiereHoraInicio': false,
    };

  }

  /// Revisa si lo dictado es una orden para cambiar un recordatorio que ya existe (en lugar de
  /// crear uno nuevo).
  ///
  /// Es una orden de cambio cuando:
  /// - usa verbos como "cambia", "modifica", "pospón" o "adelanta"; o
  /// - empieza con "mejor" o "en realidad" y hay un recordatorio previo; o
  /// - empieza con "avísame 2 días antes" y hay un recordatorio previo.
  ///
  /// [hayRecordatorioPrevio] indica si existe un recordatorio reciente que se pueda modificar.
  static bool esInstruccionModificacion(
    String texto, {
    required bool hayRecordatorioPrevio,
  }) {
    final instruccion = texto.toLowerCase().trim();

    // Verbos que indican un cambio. Con cualquiera de ellos ya es una orden de modificación.
    final modificacionRegex = RegExp(
      r'\b('
      r'cámbialo|cambialo|cámbiala|cambiala|'
      r'cambia|cambiar|'
      r'modifica|modificar|modifícalo|modificalo|'
      r'actualiza|actualizar|corrige|corregir|'
      r'renombra|renombrar|renómbralo|renombralo|'
      r'muévelo|muevelo|muévela|muevela|'
      r'posponlo|pospónlo|posponla|'
      r'adelántalo|adelantalo|adelanta|'
      r'retrásalo|retrasalo'
      r')\b',
      caseSensitive: false,
    );

    if (modificacionRegex.hasMatch(instruccion)) {
      return true;
    }

    // Frases de corrección al inicio ("mejor...", "en realidad..."). Solo cuentan si hay algo
    // que corregir.
    final correccionRegex = RegExp(
      r'^(mejor|más bien|mas bien|en realidad)\b',
      caseSensitive: false,
    );

    if (correccionRegex.hasMatch(instruccion)) {
      return hayRecordatorioPrevio;
    }

    // "Avísame 2 días antes" al inicio: cambia la anticipación del último recordatorio.
    final anticipacionRegex = RegExp(
      r'^(avísame|avisame)\s+'
      r'(un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|\d+)'
      r'\s+d[ií]as?\s+antes\b',
      caseSensitive: false,
    );

    if (anticipacionRegex.hasMatch(instruccion)) {
      return hayRecordatorioPrevio;
    }

    return false;
  }

  /// Busca una hora nueva en una orden de cambio ("cámbialo a las 5 de la tarde"). Devuelve la
  /// hora (formato de 24 h), los minutos y si la persona dijo el momento del día, o null si no
  /// encontró una hora válida.
  static Map<String, int>? interpretarHoraModificacion(String texto) {
    const numeros = <String, int>{
      'una': 1, 'uno': 1, 'dos': 2, 'tres': 3, 'cuatro': 4,
      'cinco': 5, 'seis': 6, 'siete': 7, 'ocho': 8,
      'nueve': 9, 'diez': 10, 'once': 11, 'doce': 12,
    };

    final regex = RegExp(
      r'\b(?:a\s+las?\s+|para\s+las?\s+|las\s+|'
      r'a\s+la\s+|para\s+la\s+|a\s+las?\s+)?'
      r'(\d{1,2}|una|uno|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|once|doce)'
      r'(?::(\d{1,2})|\s+y\s+(media|cuarto))?'
      r'\s*(de\s+la\s+mañana|de\s+la\s+tarde|'
      r'de\s+la\s+noche|de\s+la\s+madrugada|'
      r'del\s+mediodía|a\.?\s?m\.?|p\.?\s?m\.?|horas?)?\b',
      caseSensitive: false,
    );
    // Evita confundir el día de una fecha ("28 de octubre") con una hora.
    final sinFechas = texto.replaceAll(
      RegExp(r'\b\d{1,2}\s+de\s+'
          r'(?:enero|febrero|marzo|abril|mayo|junio|julio|'
          r'agosto|septiembre|setiembre|octubre|noviembre|diciembre)'
          r'(?:\s+(?:de|del)\s+\d{4})?\b', caseSensitive: false),
      '',
    );
    final coincidencia = regex.firstMatch(sinFechas);
    if (coincidencia == null) return null;

    final valor = coincidencia.group(1)!.toLowerCase();
    int? hora = int.tryParse(valor) ?? numeros[valor];
    if (hora == null) return null;
    int minuto = int.tryParse(coincidencia.group(2) ?? '') ?? 0;
    final fraccion = coincidencia.group(3)?.toLowerCase();
    if (fraccion == 'media') minuto = 30;
    if (fraccion == 'cuarto') minuto = 15;
    if (hora > 23 || minuto > 59) return null;

    final periodo = (coincidencia.group(4) ?? '')
        .toLowerCase().replaceAll(RegExp(r'\s+|\.'), '');
    final tarde = periodo.contains('pm') ||
        periodo.contains('tarde') || periodo.contains('noche');
    final manana = periodo.contains('am') ||
        periodo.contains('mañana') || periodo.contains('madrugada');
    final mediodia = periodo.contains('mediodía');
    if (tarde) {
      if (hora < 1 || hora > 12) return null;
      if (hora < 12) hora += 12;
    } else if (manana) {
      if (hora < 1 || hora > 12) return null;
      if (hora == 12) hora = 0;
    } else if (mediodia) {
      if (hora != 12) return null;
    }
    final explicito = periodo.isNotEmpty || hora > 12;
    return {
      'hora': hora,
      'minuto': minuto,
      'periodoExplicito': explicito ? 1 : 0,
    };
  }

  /// Busca una fecha nueva en una orden de cambio y devuelve el momento resultante, conservando
  /// la hora de [fechaActual]. Devuelve null si no entiende ninguna fecha.
  ///
  /// Entiende, en este orden: desplazamientos ("pospónlo 2 días", "adelántalo 1 día"), fechas
  /// con día y mes ("15 de marzo"), "pasado mañana", "mañana", "hoy" y días de la semana ("el
  /// viernes", "próximo lunes").
  static DateTime? interpretarFechaModificacion(
    String textoOriginal,
    DateTime fechaActual,
  ) {
    final texto = textoOriginal.toLowerCase().trim().replaceAll(
      RegExp(r'\bde\s+la\s+mañana\b', caseSensitive: false),
      '',
    );
    final hoy = DateTime.now();

    // Números escritos con letras.
    const numeros = <String, int>{
      'un': 1,
      'uno': 1,
      'una': 1,
      'dos': 2,
      'tres': 3,
      'cuatro': 4,
      'cinco': 5,
      'seis': 6,
      'siete': 7,
      'ocho': 8,
      'nueve': 9,
      'diez': 10,
    };

    // Nombres de los meses y su número.
    const meses = <String, int>{
      'enero': 1,
      'febrero': 2,
      'marzo': 3,
      'abril': 4,
      'mayo': 5,
      'junio': 6,
      'julio': 7,
      'agosto': 8,
      'septiembre': 9,
      'setiembre': 9,
      'octubre': 10,
      'noviembre': 11,
      'diciembre': 12,
    };

    // Días de la semana y su número en Dart.
    const diasSemana = <String, int>{
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miércoles': DateTime.wednesday,
      'miercoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sábado': DateTime.saturday,
      'sabado': DateTime.saturday,
      'domingo': DateTime.sunday,
    };

    // Pone la hora original del recordatorio en la fecha nueva, para no perderla.
    DateTime conservarHora(DateTime fecha) {
      return DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        fechaActual.hour,
        fechaActual.minute,
      );
    }

    // 1. Desplazamiento: "pospónlo 2 días" suma días y "adelántalo 2 días" resta días.
    final desplazamiento = RegExp(
      r'\b(posp[oó]n(?:lo|la)?|retr[aá]salo|'
      r'adel[aá]ntalo|adelanta|mu[eé]velo)\s+'
      r'(\d+|un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez)\s+d[ií]as?\b',
      caseSensitive: false,
    ).firstMatch(texto);

    if (desplazamiento != null) {
      final palabra = desplazamiento.group(2)!;
      final cantidad = int.tryParse(palabra) ?? numeros[palabra];

      if (cantidad == null) return null;

      final accion = desplazamiento.group(1)!;

      // Adelantar resta días; los demás verbos suman.
      final signo = accion.startsWith('adelant') ||
              accion.startsWith('adelánt')
          ? -1
          : 1;

      return DateTime(
        fechaActual.year,
        fechaActual.month,
        fechaActual.day + signo * cantidad,
        fechaActual.hour,
        fechaActual.minute,
      );
    }

    // 2. Fecha con día y mes, y año opcional ("15 de marzo", "15 de marzo de 2027").
    final fechaExplicita = RegExp(
      r'\b(\d{1,2})\s+de\s+'
      r'(enero|febrero|marzo|abril|mayo|junio|julio|'
      r'agosto|septiembre|setiembre|octubre|noviembre|diciembre)'
      r'(?:\s+(?:de|del)\s+(\d{4}))?\b',
      caseSensitive: false,
    ).firstMatch(texto);

    if (fechaExplicita != null) {
      final dia = int.parse(fechaExplicita.group(1)!);
      final mes = meses[fechaExplicita.group(2)!]!;
      final anioExplicito = fechaExplicita.group(3);

      // Si no dijo el año, se usa el actual.
      int anio = anioExplicito == null
          ? hoy.year
          : int.parse(anioExplicito);

      DateTime fecha = DateTime(anio, mes, dia);

      // La fecha no existe (por ejemplo, 31 de febrero).
      if (fecha.month != mes || fecha.day != dia) {
        return null;
      }

      // Si no dijo el año y la fecha ya pasó, se toma el año siguiente.
      if (anioExplicito == null) {
        final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);

        if (fecha.isBefore(hoySinHora)) {
          anio++;
          fecha = DateTime(anio, mes, dia);
        }
      }

      return conservarHora(fecha);
    }

    // 3. Palabras sueltas: "pasado mañana" (+2 días), "mañana" (+1 día) y "hoy". Se prueba
    // "pasado mañana" primero porque también contiene la palabra "mañana".
    if (RegExp(r'\bpasado\s+mañana\b').hasMatch(texto)) {
      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + 2),
      );
    }

    if (RegExp(r'\bmañana\b').hasMatch(texto)) {
      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + 1),
      );
    }

    if (RegExp(r'\bhoy\b').hasMatch(texto)) {
      return conservarHora(hoy);
    }

    // 4. Días de la semana. "Próximo" o "siguiente" apunta a la semana que viene; si dice solo
    // "el lunes" y hoy es lunes, se entiende el lunes de la próxima semana.
    for (final entrada in diasSemana.entries) {
      final expresion = RegExp(
        '\\b${entrada.key}\\b',
        caseSensitive: false,
      );

      if (!expresion.hasMatch(texto)) continue;

      final proximo = RegExp(
        '\\b(pr[oó]ximo|siguiente)\\s+${entrada.key}\\b',
        caseSensitive: false,
      ).hasMatch(texto);

      final diferencia = proximo
          ? (8 - hoy.weekday) + (entrada.value - 1)
          : (entrada.value - hoy.weekday + 7) % 7;

      final dias = !proximo && diferencia == 0
          ? 7
          : diferencia;

      return conservarHora(
        DateTime(hoy.year, hoy.month, hoy.day + dias),
      );
    }

    return null;
  }

  /// Obtiene un nombre nuevo cuando la orden pide renombrar un recordatorio.
  /// No interpreta cambios de fecha u hora como cambios de nombre.
  static String? interpretarNombreModificacion(String texto) {
    final patrones = <RegExp>[
      RegExp(
        r'\b(?:cambia|cambiar|modifica|modificar|actualiza|actualizar)\s+'
        r'(?:el\s+)?(?:nombre|texto|t[ií]tulo|descripci[oó]n)\s+'
        r'(?:(?:del|de)\s+(?:mi\s+|este\s+|el\s+)?recordatorio\s+)?'
        r'(?:a|por|como)\s+(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:renombra|renombrar|ren[oó]mbralo)\s+'
        r'(?:(?:el|mi|este)\s+)?(?:recordatorio\s+)?'
        r'(?:a|como|por)\s+(.+)$',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(?:cambia|modifica|actualiza)\s+'
        r'(?:(?:el|mi|este)\s+)?recordatorio\s+'
        r'(?:para\s+que\s+(?:diga|se\s+llame)|con\s+el\s+nombre)\s+'
        r'(.+)$',
        caseSensitive: false,
      ),
    ];

    for (final patron in patrones) {
      final coincidencia = patron.firstMatch(texto.trim());
      if (coincidencia == null) continue;
      final nombre = coincidencia.group(1)?.trim();
      if (nombre != null && nombre.isNotEmpty) return nombre;
    }
    return null;
  }

  /// Reconoce reglas de repetición sin programar notificaciones.
  /// La duración es opcional: sin ella, fechaFinRecurrencia será null.
  static Map<String, dynamic> interpretarRecurrencia(String original) {
    var texto = original.trim();
    String? unidad;
    int intervalo = 1;
    final dias = <int>[];
    int? diaMes;
    int? duracion;
    String? unidadDuracion;
    DateTime? fechaHasta;

    const numeros = <String, int>{
      'un': 1, 'uno': 1, 'una': 1, 'dos': 2, 'tres': 3,
      'cuatro': 4, 'cinco': 5, 'seis': 6, 'siete': 7,
      'ocho': 8, 'nueve': 9, 'diez': 10, 'once': 11,
      'doce': 12, 'quince': 15, 'treinta': 30,
      'primer': 1, 'primero': 1, 'segundo': 2, 'tercer': 3, 'tercero': 3,
      'tercera': 3, '3er': 3, '3ero': 3,
    };
    int? cantidad(String? valor) => valor == null
        ? null
        : (int.tryParse(valor.toLowerCase()) ?? numeros[valor.toLowerCase()]);

    const nombresDias = <String, int>{
      'lunes': 1, 'martes': 2, 'miercoles': 3, 'miércoles': 3,
      'jueves': 4, 'viernes': 5, 'sabado': 6, 'sábado': 6,
      'domingo': 7,
    };
    const meses = <String, int>{
      'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
      'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
      'septiembre': 9, 'setiembre': 9, 'octubre': 10,
      'noviembre': 11, 'diciembre': 12,
    };

    // "Durante 5 días", "por dos semanas", "durante un mes".
    final duracionRegex = RegExp(
      r'\b(?:durante|por)\s+(\d+|un|uno|una|dos|tres|cuatro|'
      r'cinco|seis|siete|ocho|nueve|diez|doce|quince|treinta)\s+'
      r'(minutos?|horas?|d[ií]as?|semanas?|mes(?:es)?|a[nñ]os?)\b',
      caseSensitive: false,
    );
    final duracionMatch = duracionRegex.firstMatch(texto);
    if (duracionMatch != null) {
      duracion = cantidad(duracionMatch.group(1));
      unidadDuracion = _unidadRecurrencia(duracionMatch.group(2)!);
      texto = texto.replaceFirst(duracionRegex, ' ').trim();
    }

    // "Hasta el 30 de noviembre" o "hasta el 30 de noviembre de 2027".
    final hastaRegex = RegExp(
      r'\bhasta\s+(?:el\s+)?(\d{1,2})\s+de\s+'
      r'(enero|febrero|marzo|abril|mayo|junio|julio|agosto|'
      r'septiembre|setiembre|octubre|noviembre|diciembre)'
      r'(?:\s+de\s+(\d{4}))?\b',
      caseSensitive: false,
    );
    final hastaMatch = hastaRegex.firstMatch(texto);
    if (hastaMatch != null) {
      final dia = int.parse(hastaMatch.group(1)!);
      final mes = meses[hastaMatch.group(2)!.toLowerCase()]!;
      final ahora = DateTime.now();
      var anio = int.tryParse(hastaMatch.group(3) ?? '') ?? ahora.year;
      var candidata = DateTime(anio, mes, dia, 23, 59, 59);
      if (candidata.day == dia && candidata.month == mes) {
        if (hastaMatch.group(3) == null && candidata.isBefore(ahora)) {
          anio++;
          candidata = DateTime(anio, mes, dia, 23, 59, 59);
        }
        if (candidata.day == dia && candidata.month == mes) {
          fechaHasta = candidata;
          texto = texto.replaceFirst(hastaRegex, ' ').trim();
        }
      }
    }

    // "El día 5 de cada mes".
    final mensualDia = RegExp(
      r'\b(?:el\s+)?d[ií]a\s+(\d{1,2})\s+de\s+cada\s+mes\b',
      caseSensitive: false,
    );
    final mensualMatch = mensualDia.firstMatch(texto);
    if (mensualMatch != null) {
      diaMes = int.parse(mensualMatch.group(1)!);
      if (diaMes >= 1 && diaMes <= 31) {
        unidad = 'meses';
        texto = texto.replaceFirst(mensualDia, ' ').trim();
      } else {
        diaMes = null;
      }
    }

    // "Todos los lunes", "cada lunes", "lunes y miércoles".
    final diasRegex = RegExp(
      r'\b(?:todos\s+los|cada)\s+'
      r'(lunes|martes|mi[eé]rcoles|jueves|viernes|s[aá]bado|domingo)'
      r'((?:\s*(?:,|y)\s*(?:lunes|martes|mi[eé]rcoles|jueves|viernes|s[aá]bado|domingo))*)\b',
      caseSensitive: false,
    );
    final diasMatch = diasRegex.firstMatch(texto);
    if (diasMatch != null && unidad == null) {
      final nombres = RegExp(
        r'lunes|martes|mi[eé]rcoles|jueves|viernes|s[aá]bado|domingo',
        caseSensitive: false,
      ).allMatches(diasMatch.group(0)!);
      for (final m in nombres) {
        final dia = nombresDias[m.group(0)!.toLowerCase()];
        if (dia != null && !dias.contains(dia)) dias.add(dia);
      }
      dias.sort();
      unidad = 'dias_semana';
      texto = texto.replaceFirst(diasRegex, ' ').trim();
    }

    // "Cada 8 horas", "cada dos días", "cada semana", "todos los días".
    final intervaloRegex = RegExp(
      r'\b(?:cada\s+(?:(\d+|un|uno|una|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|doce|quince|treinta|'
      r'primer|primero|segundo|tercer|tercero|tercera|3er|3ero)\s+)?|'
      r'todos?\s+los?\s+)'
      r'(minutos?|horas?|d[ií]as?|semanas?|mes(?:es)?|a[nñ]os?)\b',
      caseSensitive: false,
    );
    // Variantes naturales sin la palabra 'cada'.
    // Se evalúan solo cuando no hay otra regla de repetición detectada.
    final frecuenciaSimpleRegex = RegExp(
      r'\b(diariamente|diario|diaria|mensualmente|mensual|semanalmente|semanal)\b',
      caseSensitive: false,
    );
    final frecuenciaSimpleMatch = frecuenciaSimpleRegex.firstMatch(texto);
    final intervaloMatch = intervaloRegex.firstMatch(texto);
    if (intervaloMatch != null && unidad == null) {
      unidad = _unidadRecurrencia(intervaloMatch.group(2)!);
      intervalo = cantidad(intervaloMatch.group(1)) ?? 1;
      texto = texto.replaceFirst(intervaloRegex, ' ').trim();
    }

    if (unidad == null && frecuenciaSimpleMatch != null) {
      final frecuencia = frecuenciaSimpleMatch.group(1)!.toLowerCase();
      if (frecuencia.startsWith('diari')) {
        unidad = 'dias';
      } else if (frecuencia.startsWith('mensual')) {
        unidad = 'meses';
      } else if (frecuencia.startsWith('semanal')) {
        unidad = 'semanas';
      }
      if (unidad != null) {
        intervalo = 1;
        texto = texto.replaceFirst(frecuenciaSimpleRegex, ' ').trim();
      }
    }

    final esRecurrente = unidad != null && intervalo > 0;
    // No se elimina una duración aislada de una instrucción no recurrente.
    if (!esRecurrente) texto = original.trim();
    return {
      'esRecurrente': esRecurrente,
      'tipoRecurrencia': esRecurrente ? unidad : null,
      'intervaloRecurrencia': intervalo,
      'diasSemanaRecurrencia': dias,
      'diaMesRecurrencia': diaMes,
      'duracionRecurrencia': duracion,
      'unidadDuracionRecurrencia': unidadDuracion,
      'fechaHastaRecurrencia': fechaHasta,
      'textoSinRecurrencia': texto.replaceAll(RegExp(r'\s+'), ' ').trim(),
    };
  }

  static String _unidadRecurrencia(String palabra) {
    final u = palabra.toLowerCase();
    if (u.startsWith('minuto')) return 'minutos';
    if (u.startsWith('hora')) return 'horas';
    if (u.startsWith('d')) return 'dias';
    if (u.startsWith('semana')) return 'semanas';
    if (u.startsWith('mes')) return 'meses';
    return 'anios';
  }

  /// Fecha de cierre inclusiva. null significa duración indefinida.
  static DateTime? calcularFinRecurrencia(
    Map<String, dynamic> recurrencia,
    DateTime primeraFecha,
  ) {
    final hasta = recurrencia['fechaHastaRecurrencia'];
    if (hasta is DateTime) return hasta;
    final cantidad = recurrencia['duracionRecurrencia'];
    final unidad = recurrencia['unidadDuracionRecurrencia'];
    if (cantidad is! int || cantidad < 1 || unidad is! String) return null;
    // Duración contada desde el primer evento, no desde el dictado.
    DateTime finExclusivo;
    switch (unidad) {
      case 'minutos':
        finExclusivo = primeraFecha.add(Duration(minutes: cantidad));
        break;
      case 'horas':
        finExclusivo = primeraFecha.add(Duration(hours: cantidad));
        break;
      case 'dias':
        finExclusivo = primeraFecha.add(Duration(days: cantidad));
        break;
      case 'semanas':
        finExclusivo = primeraFecha.add(Duration(days: cantidad * 7));
        break;
      case 'meses':
      case 'anios':
        final meses = unidad == 'meses' ? cantidad : cantidad * 12;
        final inicioMes = DateTime(
          primeraFecha.year, primeraFecha.month + meses, 1,
          primeraFecha.hour, primeraFecha.minute,
        );
        final ultimoDia = DateTime(
          inicioMes.year, inicioMes.month + 1, 0,
        ).day;
        finExclusivo = DateTime(inicioMes.year, inicioMes.month,
            primeraFecha.day <= ultimoDia ? primeraFecha.day : ultimoDia,
            primeraFecha.hour, primeraFecha.minute);
        break;
      default:
        return null;
    }
    return finExclusivo.subtract(const Duration(microseconds: 1));
  }
}
