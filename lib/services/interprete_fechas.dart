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

    // Si no dijo fecha y esa hora ya pasó hoy, el evento se pasa a mañana.
    if (!fechaExplicita && fechaEvento.isBefore(ahora)) {
      fechaEvento = DateTime(
        fechaBase.year,
        fechaBase.month,
        fechaBase.day + 1,
        horaFinal,
        minutoFinal,
      );
    }

    // El aviso suena tantos días antes del evento como pidió (0 = el mismo día).
    final fechaRecordatorio = DateTime(
      fechaEvento.year,
      fechaEvento.month,
      fechaEvento.day - diasAnticipacion,
      fechaEvento.hour,
      fechaEvento.minute,
    );

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
      r'modifica|modifícalo|modificalo|'
      r'actualiza|corrige|'
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
    // Horas escritas con letras.
    final numeros = <String, int>{
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

    // Mismo patrón que al dictar: "a las X", minutos y momento del día.
    final regex = RegExp(
      r'\b(?:a\s+las?\s+|las\s+)'
      r'(\d{1,2}|una|uno|dos|tres|cuatro|cinco|'
      r'seis|siete|ocho|nueve|diez|once|doce)'
      r'(?::(\d{2})|\s+y\s+(media|cuarto))?'
      r'\s*(am|pm|a\.m|p\.m|a\.m\.|p\.m\.|'
      r'de la mañana|de la tarde|de la noche|'
      r'del mediodía|de la madrugada)?',
      caseSensitive: false,
    );

    final coincidencia = regex.firstMatch(texto);

    if (coincidencia == null) return null;

    final valorHora = coincidencia.group(1)!.toLowerCase();

    int? hora = int.tryParse(valorHora) ?? numeros[valorHora];

    if (hora == null) return null;

    int minuto = int.tryParse(coincidencia.group(2) ?? '') ?? 0;

    final fraccion = coincidencia.group(3)?.toLowerCase();

    if (fraccion == 'media') {
      minuto = 30;
    } else if (fraccion == 'cuarto') {
      minuto = 15;
    }

    final periodo = (coincidencia.group(4) ?? '').toLowerCase();

    // Hora imposible: se descarta.
    if (hora < 1 || hora > 23 || minuto > 59) {
      return null;
    }

    // Se guarda si la persona dijo el momento del día; si no, el controlador le preguntará "¿de
    // la mañana o de la noche?".
    bool periodoExplicito = periodo.isNotEmpty;

    // Tarde o noche suma 12 horas; mañana o madrugada convierte las 12 en 0; mediodía solo vale
    // con las 12.
    if (periodo.contains('pm') ||
        periodo.contains('p.m') ||
        periodo.contains('p.m.') ||
        periodo.contains('tarde') ||
        periodo.contains('noche')) {
      if (hora > 12) return null;
      if (hora < 12) hora += 12;
    } else if (periodo.contains('am') ||
        periodo.contains('a.m') ||
        periodo.contains('a.m.') ||
        periodo.contains('mañana') ||
        periodo.contains('madrugada')) {
      if (hora > 12) return null;
      if (hora == 12) hora = 0;
    } else if (periodo.contains('mediodía')) {
      if (hora != 12) return null;
    }

    // 'periodoExplicito' vale 1 si la persona dijo el momento del día y 0 si no.
    return {
      'hora': hora,
      'minuto': minuto,
      'periodoExplicito': periodoExplicito ? 1 : 0,
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
    final texto = textoOriginal.toLowerCase().trim();
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
}
