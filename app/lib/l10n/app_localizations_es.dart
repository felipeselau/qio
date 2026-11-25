// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Volver';

  @override
  String get create => 'Crear';

  @override
  String get remove => 'Quitar';

  @override
  String get delete => 'Eliminar';

  @override
  String get copy => 'Copiar';

  @override
  String get share => 'Compartir';

  @override
  String get print => 'Imprimir';

  @override
  String get genericActionError =>
      'No se pudo completar la acción. Inténtalo de nuevo.';

  @override
  String get authInvalidCredentials => 'Correo o contraseña incorrectos.';

  @override
  String get authInvalidEmail => 'Correo electrónico no válido.';

  @override
  String get authEmailInUse => 'Ya existe una cuenta con este correo.';

  @override
  String get authWeakPassword => 'Contraseña débil. Usa al menos 6 caracteres.';

  @override
  String get authUserDisabled => 'Esta cuenta fue desactivada.';

  @override
  String get authTooManyRequests =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

  @override
  String get authNetworkError =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get authGeneric => 'No se pudo iniciar sesión. Inténtalo de nuevo.';

  @override
  String get loginTagline => 'Sistema inteligente de filas';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameHint => 'Tu nombre';

  @override
  String get nameRequired => 'Ingresa tu nombre';

  @override
  String get emailLabel => 'Correo';

  @override
  String get emailHint => 'tu@correo.com';

  @override
  String get emailRequired => 'Ingresa el correo';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get passwordMin => 'Mínimo 6 caracteres';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get orSeparator => 'o';

  @override
  String get continueWithGoogle => 'Continuar con Google';

  @override
  String get haveAccountSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get accountTitle => 'Mi cuenta';

  @override
  String businessLine(String business) {
    return 'Negocio: $business';
  }

  @override
  String get queuesCreated => 'Filas creadas';

  @override
  String get memberSince => 'Miembro desde';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutError => 'No se pudo cerrar la sesión.';

  @override
  String get deleteAccountTitle => 'Eliminar mi cuenta';

  @override
  String get deleteAccountZone => 'Zona de riesgo';

  @override
  String get deleteAccountSubtitle =>
      'Borra tu cuenta, filas, historial, valoraciones y dispositivos. No se puede deshacer.';

  @override
  String get deleteAccountWarning =>
      'Todas tus filas, el historial de atenciones, las valoraciones, los grupos y tu cuenta se borrarán de forma permanente. Quien está en una fila tuya pierde su turno. Si eres operador de filas de otras personas, solo se quita tu vínculo.';

  @override
  String get deleteAccountConfirmLabel =>
      'Escribe ELIMINAR o tu correo para confirmar';

  @override
  String get deleteAccountPasswordLabel => 'Contraseña actual';

  @override
  String get deleteAccountGoogleHint =>
      'Confirmarás tu identidad con Google antes de eliminar.';

  @override
  String get deleteAccountConfirmButton => 'Eliminar definitivamente';

  @override
  String get deleteAccountProgress =>
      'Eliminando tus datos. Esto puede tardar unos instantes.';

  @override
  String get deleteAccountReauthFailed =>
      'No se pudo confirmar tu identidad. Revisa la contraseña e inténtalo de nuevo.';

  @override
  String get deleteAccountError =>
      'La eliminación no terminó. Parte de los datos puede haberse borrado ya. Inténtalo de nuevo para completarla.';

  @override
  String get deleteAccountRetry => 'Reintentar';

  @override
  String get deleteAccountRecentLogin =>
      'Por seguridad, confirma tu identidad de nuevo para completar la eliminación.';

  @override
  String get appearance => 'Apariencia';

  @override
  String get systemOption => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get newQueue => 'Nueva fila';

  @override
  String get queueNameLabel => 'Nombre de la fila *';

  @override
  String get queueNameHint => 'Ej: Atención en mostrador';

  @override
  String get queueNameRequired => 'Ingresa el nombre';

  @override
  String get descriptionLabel => 'Descripción (opcional)';

  @override
  String get descriptionHint => 'Describe el propósito de la fila...';

  @override
  String get avgServiceLabel => 'Tiempo promedio de atención (minutos)';

  @override
  String get invalidNumber => 'Ingresa un número válido';

  @override
  String get createQueue => 'Crear fila';

  @override
  String get myQueues => 'Mis filas';

  @override
  String get joinAsOperator => 'Entrar como operador';

  @override
  String get tourHomeFabTitle => 'Crea tu primera fila';

  @override
  String get tourHomeFabBody =>
      'Toca el + para crear una fila y generar el código QR.';

  @override
  String get tourHomeQueueTitle => 'Abre tu fila';

  @override
  String get tourHomeQueueBody =>
      'Toca la tarjeta para abrir el panel y llamar a las personas. Pausa o muestra el código QR desde los atajos de la tarjeta.';

  @override
  String get emptyQueuesTitle => 'Aún no hay filas';

  @override
  String get emptyQueuesBody =>
      'Crea tu primera fila o entra como operador con un código de invitación';

  @override
  String get sectionOwner => 'SOY EL DUEÑO';

  @override
  String get sectionOperator => 'SOY OPERADOR';

  @override
  String get sectionRequests => 'SOLICITUDES DE OPERADOR';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas esperando',
      one: '$count persona esperando',
    );
    return '$_temp0';
  }

  @override
  String createdOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Creada el $dateString';
  }

  @override
  String get youAreOperator => 'Eres operador de esta fila';

  @override
  String get requestRemovedStatus => 'Te quitaron de esta fila';

  @override
  String get requestRejectedStatus => 'Solicitud rechazada';

  @override
  String get awaitingApproval => 'Esperando aprobación';

  @override
  String get dismiss => 'Descartar';

  @override
  String get statusOpen => 'Abierta';

  @override
  String get statusPaused => 'Pausada';

  @override
  String get statusClosed => 'Cerrada';

  @override
  String get joinOperatorIntro =>
      'Pídele el código de invitación al dueño de la fila. Después de enviarlo, el dueño debe aprobar tu acceso.';

  @override
  String get inviteCodeLabel => 'Código de invitación';

  @override
  String get inviteCodeHint => 'Ej: K7M2QX';

  @override
  String get inviteCodeLength => 'El código tiene 6 caracteres';

  @override
  String get sendRequest => 'Enviar solicitud';

  @override
  String get sendRequestError =>
      'No se pudo enviar la solicitud. Inténtalo de nuevo.';

  @override
  String get cancelRequestError => 'No se pudo cancelar. Inténtalo de nuevo.';

  @override
  String get pendingBody =>
      'El dueño de la fila debe aprobar tu solicitud. Esta pantalla se actualiza sola.';

  @override
  String get requestApproved => 'Solicitud aprobada';

  @override
  String get approvedBody => 'Ya puedes atender esta fila.';

  @override
  String get requestRejected => 'Solicitud rechazada';

  @override
  String get rejectedBody => 'El dueño de la fila rechazó tu solicitud.';

  @override
  String get removedTitle => 'Te quitaron';

  @override
  String get removedBody =>
      'El dueño de la fila quitó tu acceso como operador.';

  @override
  String get requestNotFound => 'Solicitud no encontrada';

  @override
  String get requestNotFoundBody => 'La solicitud fue cancelada o eliminada.';

  @override
  String get openQueue => 'Abrir fila';

  @override
  String get cancelRequest => 'Cancelar solicitud';

  @override
  String get inviteGenerateFailed => 'No se pudo generar un código.';

  @override
  String get inviteInvalid => 'Código no válido.';

  @override
  String get inviteInvalidOrRevoked => 'Código no válido o revocado.';

  @override
  String get inviteExpired => 'Código vencido. Pídele uno nuevo al dueño.';

  @override
  String get inviteOwnQueue => 'Ya eres el dueño de esta fila.';

  @override
  String get operatorsTitle => 'Operadores';

  @override
  String get pendingRequestsSection => 'SOLICITUDES PENDIENTES';

  @override
  String get activeOperatorsSection => 'OPERADORES ACTIVOS';

  @override
  String get noPendingRequests => 'No hay solicitudes pendientes';

  @override
  String get noOperatorsYet => 'Aún no hay operadores';

  @override
  String get inviteExplain =>
      'Quien reciba el código solicita acceso desde la app. Tú apruebas cada solicitud.';

  @override
  String get noExpiration => 'Sin vencimiento';

  @override
  String validUntil(String date) {
    return 'Válido hasta $date';
  }

  @override
  String get revokeCode => 'Revocar código';

  @override
  String get previousCodeExpired => 'El código anterior venció.';

  @override
  String get validity => 'Vigencia';

  @override
  String get validityHour => '1 hora';

  @override
  String get validityDay => '24 horas';

  @override
  String get validityWeek => '7 días';

  @override
  String get generateNewCode => 'Generar nuevo código';

  @override
  String get generateCode => 'Generar código';

  @override
  String get reject => 'Rechazar';

  @override
  String get approve => 'Aprobar';

  @override
  String get removeOperatorTooltip => 'Quitar operador';

  @override
  String get removeOperatorTitle => '¿Quitar operador?';

  @override
  String removeOperatorBody(String name) {
    return '$name pierde el acceso a la fila. Las personas que ya llamó siguen en la fila.';
  }

  @override
  String get codeCopied => '¡Código copiado!';

  @override
  String shareCodeText(String queue, String code) {
    return 'Código para atender la fila \"$queue\" en Qio: $code\nAbre la app Qio > Entrar como operador.';
  }

  @override
  String get tourPanelQrTitle => 'Comparte el código QR';

  @override
  String get tourPanelQrBody =>
      'Tus clientes lo escanean para entrar a la fila, sin instalar nada.';

  @override
  String get tourPanelCallTitle => 'Llama al siguiente';

  @override
  String get tourPanelCallBody =>
      'Toca aquí para llamar a la siguiente persona de la fila.';

  @override
  String newPersonInQueue(String name) {
    return 'Nueva persona en la fila: $name';
  }

  @override
  String newPeopleInQueue(int count) {
    return '$count personas nuevas en la fila';
  }

  @override
  String get syncError => 'No se pudo sincronizar la fila. Intenta reabrirla.';

  @override
  String get accessEndedTitle => 'Acceso finalizado';

  @override
  String get accessEndedBody =>
      'Ya no eres operador de esta fila. El dueño quitó tu acceso o la fila fue eliminada.';

  @override
  String get historyTitle => 'Historial';

  @override
  String get reopen => 'Reabrir';

  @override
  String get pause => 'Pausar';

  @override
  String get close => 'Cerrar';

  @override
  String get queueClosedTitle => 'Fila cerrada';

  @override
  String get noServiceInProgress => 'No hay atención en curso';

  @override
  String get closedOwnerHint =>
      'La fila está cerrada. Puedes reabrirla o eliminarla.';

  @override
  String get closedOperatorHint =>
      'La fila está cerrada. Espera a que el dueño la reabra.';

  @override
  String get servingByOthers => 'EN ATENCIÓN POR OTROS';

  @override
  String get finishService => 'Finalizar atención';

  @override
  String get served => 'Atendido';

  @override
  String get noShow => 'No se presentó';

  @override
  String get upNext => 'PRÓXIMOS EN LA FILA';

  @override
  String get nobodyInQueue => 'Nadie en la fila';

  @override
  String get deleteQueue => 'Eliminar fila';

  @override
  String get callNext => 'Llamar al siguiente';

  @override
  String get operatorsAndInvites => 'Operadores e invitaciones';

  @override
  String get qrSemantics => 'Código QR para entrar a la fila';

  @override
  String get scanToJoin => 'Escanea para entrar a la fila';

  @override
  String get copyLinkSemantics => 'Copiar enlace de la fila';

  @override
  String get copyLink => 'Copiar enlace';

  @override
  String get printablePoster => 'Cartel para imprimir';

  @override
  String get linkCopied => '¡Enlace copiado!';

  @override
  String get deleteQueueTitle => '¿Eliminar fila?';

  @override
  String get deleteQueueBody =>
      'Esta acción es permanente. La fila y todo el historial de atenciones se borrarán.';

  @override
  String get nobodyCalled => 'Nadie llamado';

  @override
  String get callNextHint => 'Toca \"Llamar al siguiente\" para comenzar';

  @override
  String get callingNow => 'LLAMANDO AHORA';

  @override
  String waitTileSubtitle(int ticket, int minutes) {
    return '#$ticket · $minutes min';
  }

  @override
  String ticketAndName(int ticket, String name) {
    return '#$ticket $name';
  }

  @override
  String get exportTooltip => 'Exportar';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get nothingToExport => 'No hay nada para exportar con este filtro.';

  @override
  String get exportError => 'No se pudo exportar el historial.';

  @override
  String get loadHistoryError =>
      'No se pudo cargar el historial. Inténtalo de nuevo.';

  @override
  String get noHistoryYet => 'Aún no hay atenciones';

  @override
  String get noHistoryInFilter => 'No hay atenciones con este filtro';

  @override
  String get filterAll => 'Todos';

  @override
  String get periodToday => 'Hoy';

  @override
  String get period7Days => '7 días';

  @override
  String get periodAll => 'Todo';

  @override
  String get servedPlural => 'Atendidos';

  @override
  String get noShowPlural => 'No se presentaron';

  @override
  String get leftPlural => 'Abandonaron';

  @override
  String get avgWait => 'Espera promedio';

  @override
  String get avgService => 'Atención promedio';

  @override
  String get avgRating => 'Calificación promedio';

  @override
  String get resultLeft => 'Abandonó';

  @override
  String waitSubtitle(String duration) {
    return 'espera $duration';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get durationLessThanMinute => '<1 min';

  @override
  String get csvTicket => 'ticket';

  @override
  String get csvName => 'nombre';

  @override
  String get csvPhone => 'teléfono';

  @override
  String get csvResult => 'resultado';

  @override
  String get csvEntered => 'ingreso';

  @override
  String get csvCalled => 'llamado';

  @override
  String get csvFinished => 'finalizado';

  @override
  String get pdfTitle => 'Qio - Historial de atenciones';

  @override
  String pdfGeneratedAt(String date) {
    return 'Generado el $date';
  }

  @override
  String get pdfTotal => 'Total';

  @override
  String get pdfNoRecords => 'No hay atenciones en el período.';

  @override
  String get colTicket => 'Ticket';

  @override
  String get colName => 'Nombre';

  @override
  String get colPhone => 'Teléfono';

  @override
  String get colResult => 'Resultado';

  @override
  String get colEntered => 'Ingreso';

  @override
  String get colCalled => 'Llamado';

  @override
  String get colFinished => 'Finalizado';

  @override
  String get posterTitle => 'Cartel del QR';

  @override
  String get qrColor => 'COLOR DEL QR';

  @override
  String get qrColorBlue => 'Azul';

  @override
  String get qrColorBlack => 'Negro';

  @override
  String get qrColorDarkGreen => 'Verde oscuro';

  @override
  String get shareImage => 'Compartir imagen';

  @override
  String get shareImageError => 'No se pudo compartir la imagen.';

  @override
  String get printPosterError => 'No se pudo imprimir el cartel.';

  @override
  String get skip => 'OMITIR';

  @override
  String stepOf(int index, int total) {
    return '$index de $total';
  }

  @override
  String get tapToContinue => 'Toca para continuar';

  @override
  String avatarLabel(String name) {
    return 'Avatar: $name';
  }

  @override
  String get metricsTitle => 'Métricas';

  @override
  String get metricsTooltip => 'Métricas de las filas';

  @override
  String get metricsTotal => 'Atenciones';

  @override
  String get peakHoursTitle => 'Picos de demanda';

  @override
  String get peakHoursSubtitle => 'Personas que entraron por hora';

  @override
  String peakHoursTop(String hours) {
    return 'Horas más llenas: $hours';
  }

  @override
  String get noPeakData => 'Sin datos en el período';

  @override
  String get mostActiveQueues => 'Filas más activas';

  @override
  String queueActivityLine(int total, int rate) {
    return '$total atenciones · $rate% no se presentaron';
  }

  @override
  String get noMetricsData => 'Sin atenciones en el período';

  @override
  String get loadMetricsError =>
      'No se pudieron cargar las métricas. Inténtalo de nuevo.';

  @override
  String get noQueuesYet => 'Aún no tienes filas';

  @override
  String get retry => 'Reintentar';

  @override
  String get forgotPassword => 'Olvidé mi contraseña';

  @override
  String get resetEmailRequired =>
      'Ingresa tu correo para restablecer la contraseña';

  @override
  String get resetEmailSent =>
      'Si existe una cuenta con ese correo, enviamos un enlace para restablecer la contraseña.';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get offlineBanner =>
      'Sin conexión. Los datos pueden estar desactualizados.';

  @override
  String get loadErrorTitle => 'Algo salió mal';

  @override
  String get loadErrorBody =>
      'No pudimos cargar tus datos. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get hapticsTitle => 'Vibración';

  @override
  String get hapticsSubtitle =>
      'Vibrar al llamar, finalizar y confirmar acciones';

  @override
  String get analyticsTitle => 'Ayudar a mejorar Qio';

  @override
  String get analyticsSubtitle =>
      'Envía estadísticas anónimas de uso (sin nombres, teléfonos ni datos de clientes). Puedes desactivarlo cuando quieras.';

  @override
  String get nobodyInQueueHint =>
      'Cuando alguien entre por el código QR, aparecerá aquí.';

  @override
  String get emptyHistoryHint => 'Las atenciones finalizadas aparecen aquí.';

  @override
  String get emptyMetricsHint =>
      'Elige otro período o espera las primeras atenciones.';

  @override
  String get discardTitle => '¿Descartar cambios?';

  @override
  String get discardBody =>
      'Ya completaste algunos campos. Si sales ahora, perderás lo que escribiste.';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get discard => 'Descartar';

  @override
  String get maxWaitingLabel => 'Máximo de personas esperando (opcional)';

  @override
  String get maxWaitingHint => 'Sin límite';

  @override
  String get maxWaitingInvalid => 'Usa un número de 1 a 1000';

  @override
  String get queueLimitTitle => 'Límite de la fila';

  @override
  String get queueLimitNone => 'Sin límite de espera';

  @override
  String queueLimitValue(int max) {
    return 'Hasta $max personas esperando';
  }

  @override
  String get save => 'Guardar';

  @override
  String get pauseQueueTitle => 'Pausar la fila';

  @override
  String get closeQueueTitle => 'Cerrar la fila';

  @override
  String get statusMessageLabel => 'Mensaje para los clientes (opcional)';

  @override
  String get statusSuggestionBack10 => 'Vuelvo en 10 minutos';

  @override
  String get statusSuggestionBreak => 'Descanso corto';

  @override
  String get statusSuggestionClosedToday => 'Fila cerrada por hoy';

  @override
  String get resumeAtLabel => 'Regreso previsto';

  @override
  String get resumeAtNone => 'Sin previsión';

  @override
  String get clear => 'Limpiar';

  @override
  String waitingCounter(int count, int max) {
    return '$count/$max esperando';
  }

  @override
  String get callAgain => 'Llamar de nuevo';

  @override
  String get callNow => 'Llamar ahora';

  @override
  String get moveToEnd => 'Mover al final';

  @override
  String get moreActions => 'Más acciones';

  @override
  String calledTimes(int count) {
    return 'Llamado ${count}x';
  }

  @override
  String get callResent => 'Llamada reenviada';

  @override
  String movedToEnd(String name) {
    return '$name pasó al final de la fila';
  }

  @override
  String get entryUnavailable => 'Esta persona ya no está esperando';

  @override
  String get scheduleTitle => 'Horario de atención';

  @override
  String get scheduleOff => 'Desactivado';

  @override
  String scheduleHours(String days, String open, String close) {
    return '$days · $open–$close';
  }

  @override
  String get scheduleEnabled => 'Abrir y cerrar automáticamente';

  @override
  String get scheduleDays => 'Días';

  @override
  String get scheduleOpens => 'Abre';

  @override
  String get scheduleCloses => 'Cierra';

  @override
  String get scheduleInvalidDays => 'Elige al menos un día';

  @override
  String get scheduleInvalidTime =>
      'La apertura y el cierre deben ser distintos';

  @override
  String get scheduleNote =>
      'Hora de Brasilia. Si abres, pausas o cierras a mano, se mantiene hasta la próxima apertura o cierre del horario.';

  @override
  String get linkForCustomers =>
      'Este enlace es para clientes. Abriendo en el navegador.';

  @override
  String get brandTitle => 'Identidad de la fila';

  @override
  String get brandSubtitle => 'Color y logo en la página del cliente';

  @override
  String get brandColorLabel => 'Color';

  @override
  String get brandLogoLabel => 'Logo';

  @override
  String get brandChooseImage => 'Elegir imagen';

  @override
  String get brandError =>
      'No se pudo guardar. Revisa la conexión e inténtalo de nuevo.';

  @override
  String get pushTitle => 'Avisos de nuevas entradas';

  @override
  String get pushSubtitle =>
      'Notificar cuando alguien entre en la fila, incluso con la app cerrada';

  @override
  String get pushPromptTitle => '¿Recibir avisos?';

  @override
  String get pushPromptBody =>
      'Te avisamos cuando alguien entre en una de tus filas, incluso con la app cerrada. Puedes cambiarlo después en Mi cuenta.';

  @override
  String get pushPromptNotNow => 'Ahora no';

  @override
  String get pushPromptEnable => 'Activar';

  @override
  String get pushDenied =>
      'Permiso denegado. Activa las notificaciones en los ajustes del sistema.';

  @override
  String get byOperatorTitle => 'Por agente';

  @override
  String get operatorFilterAll => 'Todas las filas';

  @override
  String get ownerAttendant => 'Dueño';

  @override
  String get formerOperator => 'ex operador';

  @override
  String get noOperatorData => 'Ninguna atención por agente en el período';

  @override
  String historyTruncatedWarning(int limit) {
    return 'Mostrando solo los $limit registros más recientes de una fila; las cifras pueden estar incompletas.';
  }

  @override
  String operatorCountsLine(int served, int noShow) {
    return '$served atendidos · $noShow no se presentaron';
  }

  @override
  String operatorDetailLine(String avg, String rating) {
    return 'Atención promedio: $avg · Valoración: $rating';
  }

  @override
  String get operatorFilterLabel => 'Filtrar por fila';

  @override
  String get metricsPdfTitle => 'Qio - Métricas de las filas';

  @override
  String get csvPeriod => 'período';

  @override
  String get csvScope => 'alcance por agente';

  @override
  String get csvGeneratedAt => 'generado el';

  @override
  String get csvMetric => 'métrica';

  @override
  String get csvValue => 'valor';

  @override
  String get csvHour => 'hora';

  @override
  String get csvEntries => 'entradas';

  @override
  String get csvPosition => 'posición';

  @override
  String get csvQueue => 'fila';

  @override
  String get csvTotal => 'total';

  @override
  String get csvServed => 'atendidos';

  @override
  String get csvNoShow => 'no se presentaron';

  @override
  String get csvLeft => 'desistieron';

  @override
  String get csvNoShowRatePct => 'tasa de ausencia (%)';

  @override
  String get csvAvgWaitMin => 'espera promedio (min)';

  @override
  String get csvAvgServiceMin => 'atención promedio (min)';

  @override
  String get csvAvgRating => 'valoración promedio';

  @override
  String get csvRatingCount => 'cant. valoraciones';

  @override
  String get csvAttendant => 'agente';

  @override
  String get exportMetricsError => 'No se pudieron exportar las métricas.';

  @override
  String get groups => 'Grupos';

  @override
  String get groupNew => 'Nuevo grupo…';

  @override
  String get groupRename => 'Renombrar grupo';

  @override
  String get groupDelete => 'Eliminar grupo';

  @override
  String groupDeleteConfirm(String name) {
    return '¿Eliminar el grupo \"$name\"? Sus filas quedan sin grupo.';
  }

  @override
  String get groupNone => 'Sin grupo';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String groupLimitReached(int max) {
    return 'Límite de $max grupos alcanzado.';
  }

  @override
  String queueLimitReached(int max) {
    return 'Límite de $max filas alcanzado. Elimina una fila para crear otra.';
  }

  @override
  String get groupLabel => 'Grupo';

  @override
  String get groupsEmpty =>
      'Aún no hay grupos. Crea uno para organizar tus filas.';

  @override
  String get groupPermissionDenied =>
      'Sin permiso para cambiar grupos. Actualiza la app e inténtalo de nuevo.';

  @override
  String get metricsScopeLabel => 'Alcance de las métricas';

  @override
  String get metricsScopeAll => 'Todas las filas';

  @override
  String metricsScopeGroup(String name) {
    return 'Grupo: $name';
  }

  @override
  String metricsScopeQueue(String name) {
    return 'Fila: $name';
  }

  @override
  String get groupCompareTitle => 'Comparación de filas del grupo';

  @override
  String groupCompareLine(int total, String wait, int rate, String rating) {
    return '$total atendimientos · espera $wait · $rate% no se presentaron · nota $rating';
  }

  @override
  String get csvDataScope => 'alcance de las métricas';

  @override
  String get groupsUnavailable =>
      'Grupos no disponibles. Actualiza la app o las reglas de Firestore.';

  @override
  String get alertsTitle => 'Alertas operativas';

  @override
  String get alertsEnable => 'Recibir alertas de esta fila';

  @override
  String get alertsWaitLimit => 'Espera estimada superior a';

  @override
  String get alertsNoShowLimit => 'Ausencias hoy a partir de';

  @override
  String get alertsIdleLimit => 'Fila detenida con gente esperando por más de';

  @override
  String get alertsCooldown => 'Intervalo mínimo entre alertas';

  @override
  String get alertsPushOff =>
      'Las notificaciones están desactivadas. Actívalas para recibir alertas.';

  @override
  String get alertsOff => 'Desactivado';

  @override
  String alertsActive(int count) {
    return '$count reglas activas';
  }

  @override
  String alertsMinutes(int n) {
    return '$n min';
  }

  @override
  String alertsPercent(int n) {
    return '$n%';
  }

  @override
  String get alertsNoRule => 'Activa al menos una regla para recibir alertas.';

  @override
  String get alertsNotify => 'Recibir alertas en esta cuenta';

  @override
  String get waitDistributionTitle => 'Espera y llamadas';

  @override
  String get medianWait => 'Mediana';

  @override
  String get p90Wait => 'P90';

  @override
  String get waitBucketUnder5 => 'Menos de 5 min';

  @override
  String get waitBucket5to15 => '5–15 min';

  @override
  String get waitBucket15to30 => '15–30 min';

  @override
  String get waitBucketOver30 => 'Más de 30 min';

  @override
  String get recallsTitle => 'Re-llamadas';

  @override
  String get skipsTitle => 'Movidos al final';

  @override
  String recallsStat(int entries, int total, int pct, int recalls) {
    return '$entries entradas de $total ($pct%) · $recalls re-llamadas';
  }

  @override
  String skipsStat(int entries, int total, int skips) {
    return '$entries entradas de $total · $skips movidos al final';
  }

  @override
  String get csvWaitSamples => 'muestras de espera';

  @override
  String get csvMedianWaitMin => 'mediana (min)';

  @override
  String get csvP90WaitMin => 'P90 (min)';

  @override
  String get csvWaitRange => 'rango de espera';

  @override
  String get csvCalledEntries => 'entradas llamadas';

  @override
  String get csvRecallsTotal => 're-llamadas';

  @override
  String get csvRecalledEntries => 'entradas con re-llamada';

  @override
  String get csvRecallRatePct => 'entradas con re-llamada sobre llamadas (%)';

  @override
  String get csvSkipsTotal => 'movidos al final';

  @override
  String get csvSkippedEntries => 'entradas movidas al final';

  @override
  String get p90Insufficient => 'muestras insuficientes';

  @override
  String get weekdayDemandTitle => 'Días de mayor movimiento';

  @override
  String get heatmapTitle => 'Mapa de calor: día × hora';

  @override
  String demandPeakSummary(String day, String from, String to) {
    return 'Pico: $day, $from–$to';
  }

  @override
  String heatmapCellSemantics(String day, String hour, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count llegadas',
      one: '1 llegada',
    );
    return '$day, $hour: $_temp0';
  }

  @override
  String get csvWeekday => 'día';

  @override
  String get csvArrivals => 'llegadas';

  @override
  String get heatmapLegendLess => 'menos';

  @override
  String get heatmapLegendMore => 'más';

  @override
  String weekdayChartSemantics(String details) {
    return 'Llegadas por día: $details';
  }

  @override
  String get period30Days => '30 días';

  @override
  String get periodCustom => 'Personalizado';

  @override
  String deltaUp(String pct) {
    return '▲ $pct%';
  }

  @override
  String deltaDown(String pct) {
    return '▼ $pct%';
  }

  @override
  String get deltaSame => '= estable';

  @override
  String deltaPoints(String pp) {
    return '$pp p.p.';
  }

  @override
  String get deltaRose => 'subió';

  @override
  String get deltaFell => 'bajó';

  @override
  String get deltaVsPrevious => 'vs. período anterior';

  @override
  String get trendTitle => 'Tendencia diaria';

  @override
  String get trendSeriesTotal => 'Atenciones por día';

  @override
  String get trendSeriesWait => 'Espera promedio';

  @override
  String get trendSeriesNoShow => 'No se presentó';

  @override
  String trendSummary(String avg, String peakDay) {
    return 'Promedio de $avg por día, pico el $peakDay';
  }

  @override
  String get csvDate => 'fecha';

  @override
  String get csvCompareTitle => 'Comparativo con el período anterior';

  @override
  String get csvCurrent => 'actual';

  @override
  String get csvPrevious => 'anterior';

  @override
  String get csvDeltaPct => 'variación (%)';

  @override
  String get csvDeltaPoints => 'variación (p.p.)';

  @override
  String get pdfVsPrevious => 'vs. anterior';

  @override
  String customRangeLimited(int days) {
    return 'Intervalo limitado a $days días';
  }

  @override
  String deltaPointsUp(String pp) {
    return '▲ $pp p.p.';
  }

  @override
  String deltaPointsDown(String pp) {
    return '▼ $pp p.p.';
  }

  @override
  String get trendToggleWait => 'Espera';

  @override
  String get trendToggleNoShow => 'No-show';

  @override
  String trendMax(String value) {
    return 'máx. $value';
  }

  @override
  String trendDaySummary(String day, int count, String series, String value) {
    return '$day: $count atenciones, $series $value';
  }

  @override
  String get queueModeLabel => 'Modo de la fila';

  @override
  String get modeQueue => 'Por orden de llegada';

  @override
  String get modeSchedule => 'Hora marcada';

  @override
  String get slotsEditorTitle => 'Horarios';

  @override
  String get slotsEditorHint =>
      'Zona horaria America/Sao_Paulo; se repiten todos los días';

  @override
  String get slotTime => 'Horario';

  @override
  String slotCapacity(int count) {
    return 'Cupos: $count';
  }

  @override
  String get addSlot => 'Agregar horario';

  @override
  String get removeSlot => 'Quitar horario';

  @override
  String get slotsRequired => 'Agrega al menos un horario';

  @override
  String get slotsDuplicate => 'Hay horarios repetidos';

  @override
  String slotsTooMany(int max) {
    return 'Máximo $max horarios';
  }

  @override
  String get slotsInvalid => 'Horario o cupos inválidos';

  @override
  String slotsOutsideSchedule(String time) {
    return 'Fuera del horario de atención: $time';
  }

  @override
  String slotsTileSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horarios',
      one: '1 horario',
    );
    return '$_temp0';
  }

  @override
  String waitTileSlot(String time) {
    return 'Horario $time';
  }

  @override
  String get slotTimeChangeWarning =>
      'Quienes ya entraron en este horario conservan su cupo; los cupos ocupados siguen contando.';

  @override
  String get editQueue => 'Editar fila';

  @override
  String get editQueueHint => 'Nombre, descripción y tiempo medio';

  @override
  String get queueUpdated => 'Fila actualizada';

  @override
  String get duplicateQueue => 'Duplicar fila';

  @override
  String get duplicateQueueHint =>
      'Copia límite, horario, color, modo, grupo y alertas';

  @override
  String get duplicateQueueCopyWord => 'copia';

  @override
  String get queueDuplicated => 'Fila duplicada';

  @override
  String get advancedOptions => 'Opciones avanzadas';

  @override
  String get queueNameTooLong => 'Máximo 60 caracteres';

  @override
  String get descriptionTooLong => 'Máximo 300 caracteres';

  @override
  String get avgServiceInvalid => 'Indica de 1 a 240 minutos';

  @override
  String get avgServiceAutoHint =>
      'El tiempo manual solo vale hasta que exista la estimación automática, calculada con las atenciones.';

  @override
  String get savingQueue => 'Guardando…';

  @override
  String get actionErrorOffline =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get actionErrorAccessEnded =>
      'Acceso finalizado o sin permiso para esta acción.';

  @override
  String get actionErrorConflict => 'La fila cambió. Inténtalo de nuevo.';

  @override
  String get undo => 'Deshacer';

  @override
  String finishedServedUndo(String name) {
    return '$name marcado como atendido';
  }

  @override
  String finishedNoShowUndo(String name) {
    return '$name marcado como no se presentó';
  }

  @override
  String get queueSettingsTitle => 'Configuración de la cola';

  @override
  String get queueQrShortcut => 'Código QR de la cola';

  @override
  String get queueQrTitle => 'Código QR';

  @override
  String get queueGoneNotice => 'Esta cola ya no existe';

  @override
  String get tourPanelSettingsTitle => 'Código QR y configuración';

  @override
  String get tourPanelSettingsBody =>
      'Toca el engranaje para ver el código QR y ajustar la cola.';

  @override
  String get tourHomeAccountTitle => 'Tu cuenta e invitaciones';

  @override
  String get tourHomeAccountBody =>
      'Aquí están tu cuenta y la opción de entrar como operador con un código de invitación.';

  @override
  String get quickQr => 'Código QR';

  @override
  String quickPauseLabel(String name) {
    return 'Pausar fila $name';
  }

  @override
  String quickReopenLabel(String name) {
    return 'Reabrir fila $name';
  }

  @override
  String quickQrLabel(String name) {
    return 'Mostrar código QR de la fila $name';
  }

  @override
  String get searchQueuesHint => 'Buscar fila por nombre';

  @override
  String get sortQueues => 'Ordenar filas';

  @override
  String get sortByName => 'Nombre';

  @override
  String get sortByRecent => 'Más recientes';

  @override
  String get sortByWaiting => 'Más espera';

  @override
  String get noQueuesMatch => 'Ninguna fila encontrada';

  @override
  String get addPerson => 'Agregar persona';

  @override
  String get addPersonTitle => 'Agregar persona a la fila';

  @override
  String get addPersonHint =>
      'Para quien está en el mostrador y no usa el código QR.';

  @override
  String get manualPhoneLabel => 'Teléfono (opcional)';

  @override
  String get manualPhoneInvalid => 'Usa el formato (00) 00000-0000';

  @override
  String get manualNameRequired => 'Ingresa un nombre de hasta 60 caracteres';

  @override
  String get manualSlotLabel => 'Horario';

  @override
  String manualSlotOption(String time, int capacity) {
    return '$time ($capacity lugares)';
  }

  @override
  String get manualSlotRequiredField => 'Elige un horario';

  @override
  String get manualAddConfirm => 'Agregar';

  @override
  String manualAdded(String name, int ticket) {
    return '$name entró en la fila con el turno $ticket';
  }

  @override
  String get manualBadge => 'Mostrador';

  @override
  String get manualAddQueueFull => 'La fila está llena en este momento.';

  @override
  String get manualAddSlotFull => 'Este horario está lleno.';

  @override
  String get manualAddSlotRequired => 'Elige un horario válido.';

  @override
  String get manualAddSlotPassed => 'Este horario ya pasó.';

  @override
  String get manualAddNotOpen =>
      'La fila debe estar abierta para agregar personas.';

  @override
  String get manualAddInvalid => 'Revisa el nombre y el teléfono ingresados.';

  @override
  String get manualAddRateLimited =>
      'Demasiadas altas en poco tiempo. Espera unos minutos.';

  @override
  String get manualAddPhoneDuplicate => 'Este teléfono ya está en la fila.';

  @override
  String callPhoneTooltip(String name) {
    return 'Llamar a $name';
  }

  @override
  String get callPhoneFailed => 'No se pudo abrir el marcador';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get termsOfUse => 'Términos de uso';

  @override
  String get posterSize => 'TAMAÑO DEL CARTEL';

  @override
  String get posterSizeA4 => 'A4';

  @override
  String get posterSizeA5 => 'A5';

  @override
  String get posterSizeTable => 'Tarjeta de mesa (10×15 cm)';

  @override
  String get posterHeadlineLabel => 'Frase en el cartel (opcional)';

  @override
  String get posterHeadlineHint => 'Ej.: Pide tu lugar sin esperar de pie';

  @override
  String get posterHeadlineInvalid => 'Usa hasta 60 caracteres.';

  @override
  String get sharePdf => 'Compartir PDF';

  @override
  String get sharePdfError => 'No se pudo compartir el PDF.';

  @override
  String posterPreviewSemantics(String size) {
    return 'Vista previa del cartel, $size';
  }

  @override
  String get slugTitle => 'Enlace corto';

  @override
  String get slugNone => 'Sin definir';

  @override
  String get slugRemove => 'Quitar enlace corto';

  @override
  String get slugDialogLabel => 'Nombre del enlace';

  @override
  String get slugDialogHint => 'mi-tienda';

  @override
  String slugPreview(String url) {
    return 'Enlace: $url';
  }

  @override
  String get slugInvalid =>
      'Usa de 3 a 40 letras minúsculas, números o guiones, sin guion al inicio ni al final.';

  @override
  String get slugReservedError => 'Ese nombre está reservado. Elige otro.';

  @override
  String get slugTakenError => 'Ese enlace ya está en uso. Elige otro.';

  @override
  String get slugSaved => 'Enlace corto guardado';

  @override
  String get slugRemoved => 'Enlace corto eliminado';

  @override
  String get slugReleaseNotice =>
      'Cambiar el enlace invalida los QR impresos con el enlace anterior. El enlace anterior queda reservado para ti por 30 días.';

  @override
  String get posterNameLossy =>
      'Algunos caracteres no existen en la fuente del PDF y se omitirán o reemplazarán.';

  @override
  String get posterNameFallback => 'Fila';

  @override
  String get exportCsvWithPhone => 'Exportar CSV con teléfono';

  @override
  String get exportPdfWithPhone => 'Exportar PDF con teléfono';

  @override
  String get exportPhoneTitle => '¿Incluir teléfono?';

  @override
  String get exportPhoneWarning =>
      'El teléfono es un dato personal (LGPD). Por defecto la exportación no lo incluye. Inclúyelo solo si lo necesitas y protege el archivo.';

  @override
  String get exportPhoneConfirm => 'Incluir teléfono';

  @override
  String get anonymizePhoneTitle => 'No guardar el teléfono en el historial';

  @override
  String get anonymizePhoneHint =>
      'Al terminar una atención, el teléfono no se guarda en el historial.';

  @override
  String get expiryTitle => 'Expirar entradas olvidadas';

  @override
  String get expiryHint =>
      'Quita de la fila a quien quedó esperando sin actividad. No afecta a quien ya fue llamado.';

  @override
  String expiryAfterHours(int hours) {
    return 'Expirar tras $hours h';
  }

  @override
  String get expiryClearOnClose => 'Vaciar la fila al cerrar por horario';

  @override
  String get expiryResetTicketDaily => 'Reiniciar el número cada día';

  @override
  String get expiryResetTicketDailyHint =>
      'Se reinicia la primera vez que la fila queda vacía cada día nuevo.';

  @override
  String get dataSubjectTitle => 'Datos de un cliente';

  @override
  String get dataSubjectSubtitle =>
      'Atiende solicitudes de acceso, corrección o eliminación de datos hechas por un cliente (LGPD).';

  @override
  String get dataSubjectPhoneLabel => 'Teléfono del cliente';

  @override
  String get dataSubjectSearch => 'Buscar';

  @override
  String get dataSubjectNone =>
      'No se encontraron datos para este teléfono en tus filas.';

  @override
  String dataSubjectFound(int count) {
    return 'Encontrado en $count fila(s)';
  }

  @override
  String dataSubjectQueueCounts(int history, int feedback, int entries) {
    return '$history en el historial, $feedback valoraciones, $entries en la fila ahora';
  }

  @override
  String dataSubjectPeriod(String from, String to) {
    return 'Del $from al $to';
  }

  @override
  String get dataSubjectExport => 'Exportar datos (CSV)';

  @override
  String get dataSubjectExportTruncated =>
      'La exportación se limitó a los primeros 5000 registros.';

  @override
  String get dataSubjectAnonymize => 'Anonimizar';

  @override
  String get dataSubjectDelete => 'Eliminar';

  @override
  String get dataSubjectConfirmTitleAnonymize =>
      '¿Anonimizar los datos de este cliente?';

  @override
  String get dataSubjectConfirmTitleDelete =>
      '¿Eliminar los datos de este cliente?';

  @override
  String get dataSubjectConfirmBodyAnonymize =>
      'El nombre pasa a \"Anónimo\", el teléfono se quita del historial y los comentarios de valoración se borran. Si el cliente está en alguna fila ahora, se le quita. No se puede deshacer.';

  @override
  String get dataSubjectConfirmBodyDelete =>
      'Borra el historial y las valoraciones de este teléfono y quita al cliente de cualquier fila activa. No se puede deshacer.';

  @override
  String get dataSubjectConfirmLabel =>
      'Escribe el teléfono de nuevo para confirmar';

  @override
  String get dataSubjectConfirmButton => 'Confirmar';

  @override
  String dataSubjectDone(int count) {
    return 'Listo: $count registro(s) tratado(s).';
  }

  @override
  String get dataSubjectPartial =>
      'Algunos registros no se trataron. Busca de nuevo e inténtalo otra vez.';

  @override
  String get dataSubjectRateLimited =>
      'Demasiadas consultas seguidas. Espera un poco e inténtalo de nuevo.';

  @override
  String get dataSubjectAuditNote =>
      'Cada consulta queda registrada para auditoría, sin nombre ni teléfono.';

  @override
  String get dataSubjectReauthTitle => 'Confirma tu identidad';

  @override
  String get dataSubjectReauthHint =>
      'Vas a confirmar tu identidad con Google.';

  @override
  String get dataSubjectReauthButton => 'Confirmar identidad';

  @override
  String cqStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get cqContinue => 'Continuar';

  @override
  String get cqSkip => 'Omitir';

  @override
  String get cqQuickCreate => 'Crear ahora';

  @override
  String get cqMoreDetails => 'Más detalles';

  @override
  String get cqNameTitle => '¿Cómo se llama la fila?';

  @override
  String get cqNameHint =>
      'Solo el nombre basta. El resto se ajusta después en el panel.';

  @override
  String get cqModeTitle => '¿Cómo entra la gente?';

  @override
  String get cqModeQueueHint => 'Quien llega entra al final de la fila.';

  @override
  String get cqModeScheduleHint =>
      'Cada persona elige uno de los horarios que usted define.';

  @override
  String get cqSuggestionsTitle => 'Sugerencias de horarios';

  @override
  String get cqSuggestEvery30 => 'Agregar horarios cada 30 min, de 9 a 17 h';

  @override
  String get cqSuggestEveryHour => 'Agregar horarios cada hora, de 9 a 17 h';

  @override
  String get cqCapacityTitle => 'Tiempo medio y límite de espera';

  @override
  String cqCapacityHint(int minutes) {
    return 'Usamos el tiempo medio para estimar la espera. Si omite, valen $minutes min por atención y sin límite de personas.';
  }

  @override
  String get cqAppearanceTitle => 'Elija un color';

  @override
  String get cqAppearanceHint =>
      'Aparece en la página que ve el cliente. Opcional.';

  @override
  String get cqScheduleTitle => '¿Cuándo funciona la fila?';

  @override
  String get cqScheduleHint =>
      'Por defecto la fila está siempre abierta. Puede pausarla o cerrarla cuando quiera.';

  @override
  String get cqReviewTitle => 'Revise y cree';

  @override
  String get cqReviewHint => 'Toque en Editar para cambiar cualquier ítem.';

  @override
  String get cqEdit => 'Editar';

  @override
  String get cqSummaryEntry => 'Entrada';

  @override
  String get cqSummaryCapacity => 'Tiempo y límite';

  @override
  String get cqSummarySchedule => 'Funcionamiento';

  @override
  String cqAverageTime(String time) {
    return 'Tiempo medio: $time';
  }

  @override
  String cqWaitingLimit(String limit) {
    return 'Límite de espera: $limit';
  }

  @override
  String cqLimitPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get cqAlwaysOpen => 'Siempre abierta';

  @override
  String get cqNoExpiry => 'No expirar';

  @override
  String get cqDefaultColor => 'Predeterminado';

  @override
  String get cqGroupChosen => 'En un grupo';

  @override
  String get cqSummaryName => 'Nombre';

  @override
  String get cqCreateTimeout =>
      'Sin respuesta. Puede que la fila se haya creado: revise su lista antes de intentarlo de nuevo.';

  @override
  String get cqResumeTitle => '¿Continuar donde lo dejaste?';

  @override
  String get cqResumeBody =>
      'Tienes una fila en curso que no se creó. ¿Quieres continuar donde lo dejaste o descartarla?';

  @override
  String get cqResume => 'Continuar';

  @override
  String get cqDiscardDraft => 'Descartar';

  @override
  String get cqSaveDraft => 'Guardar borrador';

  @override
  String get cqDraftDiscardBody =>
      'Ya completaste algunos campos. Guarda un borrador para continuar después o descarta lo que escribiste.';

  @override
  String get cqCreatedTitle => 'Fila creada';

  @override
  String get cqCreatedHint =>
      'Comparta el enlace o muestre el QR para que las personas entren.';

  @override
  String get cqOpenPanel => 'Abrir panel';

  @override
  String get cqPolishTitle => 'Deje su fila más linda y completa';

  @override
  String get cqShortcutLogo => 'Logo y color';

  @override
  String get cqShortcutShortLink => 'Enlace corto';

  @override
  String get cqShortcutOperators => 'Operadores';

  @override
  String get cqShortcutAlerts => 'Alertas';

  @override
  String get cqLimitTitle => 'Límite de filas alcanzado';

  @override
  String get cqCheckingLimit => 'Verificando su límite de filas';

  @override
  String get cqShareLink => 'Compartir enlace';

  @override
  String get cqAlertsTitle => '¿Quiere recibir alertas de esta fila?';

  @override
  String get cqAlertsHint =>
      'Opcional. Le avisamos cuando la espera, la inasistencia o la fila detenida superen el límite que elija.';

  @override
  String get cqAlertsPushNote =>
      'Los avisos llegan como notificaciones. Si esta cuenta los recibe es una opción de la pantalla Alertas operativas, en los ajustes de la fila.';

  @override
  String get cqSummaryAlerts => 'Alertas';

  @override
  String get metricsScopeUngrouped => 'Filas sin grupo';

  @override
  String get groupOverviewTitle => 'Por grupo';

  @override
  String get groupOverviewHint => 'Toque un grupo para ver solo sus filas.';

  @override
  String get groupOverviewOpenHint => 'Ver solo este grupo';

  @override
  String metricsGroupQueues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return '$_temp0';
  }

  @override
  String get groupPartialData => 'datos parciales';

  @override
  String get cmpColQueue => 'Fila';

  @override
  String get cmpColGroup => 'Grupo';

  @override
  String get cmpColServed => 'Atend.';

  @override
  String get cmpColWait => 'Espera';

  @override
  String get cmpColNoShow => 'Ausentes';

  @override
  String get cmpColRating => 'Nota';

  @override
  String sortByHint(String column) {
    return 'Ordenar por $column';
  }

  @override
  String get sortAscending => 'orden ascendente';

  @override
  String get sortDescending => 'orden descendente';

  @override
  String get scopePickerTitle => 'Elegir alcance';

  @override
  String get scopeSearchHint => 'Buscar grupo o fila';

  @override
  String get scopeNoResults => 'Sin resultados';

  @override
  String get csvGroup => 'grupo';

  @override
  String get csvQueuesCount => 'filas';

  @override
  String get csvPartialData => 'datos parciales';

  @override
  String get csvYes => 'sí';

  @override
  String get csvNo => 'no';

  @override
  String get csvDeltaTotalPct => 'variación atendimientos (%)';

  @override
  String get csvDeltaWaitPct => 'variación espera media (%)';

  @override
  String get csvDeltaMedianPct => 'variación mediana (%)';

  @override
  String get csvDeltaP90Pct => 'variación P90 (%)';

  @override
  String get csvDeltaNoShowPoints => 'variación inasistencia (p.p.)';

  @override
  String groupSectionQueues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '$count fila',
    );
    return '$_temp0';
  }

  @override
  String groupSectionWaiting(int count) {
    return '$count esperando';
  }

  @override
  String get groupSectionExpanded => 'expandido';

  @override
  String get groupSectionCollapsed => 'contraído';

  @override
  String groupSectionSemantics(
    String name,
    String queues,
    String waiting,
    String state,
  ) {
    return '$name, $queues, $waiting, $state';
  }

  @override
  String groupChipSemantics(String name) {
    return 'Grupo: $name';
  }

  @override
  String groupQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
      zero: 'Sin filas',
    );
    return '$_temp0';
  }

  @override
  String groupDeleteConfirmCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas quedarán sin grupo.',
      one: '1 fila quedará sin grupo.',
    );
    return '¿Eliminar el grupo \"$name\"? $_temp0';
  }

  @override
  String groupBatchMenuLabel(String name) {
    return 'Acciones en lote del grupo $name';
  }

  @override
  String get groupPauseAll => 'Pausar todas';

  @override
  String get groupCloseAll => 'Cerrar todas';

  @override
  String get groupReopenAll => 'Reabrir todas';

  @override
  String groupBatchConfirmPause(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return '¿Pausar $_temp0 del grupo \"$name\"?';
  }

  @override
  String groupBatchConfirmClose(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return '¿Cerrar $_temp0 del grupo \"$name\"?';
  }

  @override
  String groupBatchConfirmReopen(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return '¿Reabrir $_temp0 del grupo \"$name\"?';
  }

  @override
  String groupBatchDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas actualizadas',
      one: '1 fila actualizada',
    );
    return '$_temp0';
  }

  @override
  String groupBatchPartial(int done, int total) {
    return '$done de $total actualizadas. Inténtalo de nuevo con el resto.';
  }

  @override
  String get groupBatchEmpty => 'No hay filas del grupo para actualizar.';

  @override
  String groupReorderHandle(String name) {
    return 'Arrastrar para reordenar el grupo \"$name\"';
  }

  @override
  String get groupMoveUp => 'Mover hacia arriba';

  @override
  String get groupMoveDown => 'Mover hacia abajo';

  @override
  String groupMoved(String name, int position) {
    return 'Grupo \"$name\" en la posición $position';
  }

  @override
  String get groupColor => 'Color del grupo';

  @override
  String groupColorOf(String name) {
    return 'Color del grupo \"$name\"';
  }

  @override
  String get groupColorNone => 'Sin color';

  @override
  String get queueSelect => 'Seleccionar filas';

  @override
  String get selectionExit => 'Salir de la selección';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas seleccionadas',
      one: '1 fila seleccionada',
      zero: 'Ninguna fila seleccionada',
    );
    return '$_temp0';
  }

  @override
  String queueSelectLabel(String name) {
    return 'Seleccionar la fila $name';
  }

  @override
  String get moveToGroup => 'Mover a un grupo…';

  @override
  String moveToGroupTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mover $count filas a',
      one: 'Mover 1 fila a',
    );
    return '$_temp0';
  }

  @override
  String moveGroupDone(int count, String group) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas movidas',
      one: '1 fila movida',
    );
    return '$_temp0 a \"$group\"';
  }

  @override
  String moveGroupPartial(int done, int total) {
    return '$done de $total filas movidas. Inténtalo de nuevo con las demás.';
  }

  @override
  String get moveGroupEmpty =>
      'Ninguna de las filas seleccionadas se pudo mover.';

  @override
  String get groupApplyAlerts => 'Aplicar alertas a todas las filas';

  @override
  String groupAlertsDialogTitle(String name) {
    return 'Alertas del grupo \"$name\"';
  }

  @override
  String get groupAlertsDialogHint =>
      'Esta configuración se copiará a todas las filas del grupo, en lugar de la actual.';

  @override
  String get groupAlertsContinue => 'Continuar';

  @override
  String groupAlertsConfirm(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return '¿Aplicar esta configuración de alertas a $_temp0 del grupo \"$name\"? Los alertas actuales de esas filas se reemplazarán.';
  }

  @override
  String get groupAlertsApply => 'Aplicar';

  @override
  String groupAlertsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return 'Alertas aplicados a $_temp0';
  }

  @override
  String get groupHistoryTitle => 'Historial del grupo';

  @override
  String get groupHistoryOpen => 'Historial del grupo';

  @override
  String get groupHistoryNoQueues => 'Ninguna fila en este grupo';

  @override
  String get groupHistoryNoQueuesHint =>
      'Agrega filas al grupo para ver el historial consolidado.';

  @override
  String groupHistoryTruncated(int limit, String queues) {
    return 'Mostrando solo los $limit registros más recientes de cada fila. Filas con historial recortado: $queues.';
  }

  @override
  String groupHistoryShowMore(int shown, int total) {
    return 'Mostrar más ($shown de $total)';
  }

  @override
  String historyQueueOrigin(String name) {
    return 'Fila: $name';
  }

  @override
  String get colQueue => 'Fila';

  @override
  String infoButtonSemantics(String name) {
    return 'Explicación del indicador: $name';
  }

  @override
  String get infoWhat => 'Qué es';

  @override
  String get infoHow => 'Cómo se calcula';

  @override
  String get infoData => 'Datos usados';

  @override
  String get infoUse => 'Para qué sirve';

  @override
  String get infoClose => 'Cerrar';

  @override
  String get attColService => 'Tiempo medio';

  @override
  String get attColDeviation => 'Desvío';

  @override
  String get attColRate => 'Atend./h';

  @override
  String get attColIdle => 'Ocioso';

  @override
  String attInsufficientNote(int samples) {
    return '— indica muestra insuficiente (menos de $samples atenciones o ventana corta).';
  }

  @override
  String attRowSpoken(
    String name,
    int served,
    String service,
    String deviation,
    String rate,
    String idle,
    int noShow,
    String rating,
  ) {
    return '$name. $served atendidos, tiempo medio $service, desvío $deviation, $rate atenciones por hora, ocioso $idle, $noShow ausentes, nota $rating';
  }

  @override
  String get attChartTitleHour => 'Atenciones por hora del día';

  @override
  String get attChartTitleShift => 'Atenciones por turno';

  @override
  String get attChartModeHour => 'Hora';

  @override
  String get attChartModeShift => 'Turno';

  @override
  String get attChartOperatorLabel => 'Atendente del gráfico';

  @override
  String get attChartAll => 'Todos los atendentes';

  @override
  String get attChartEmpty => 'Sin atenciones concluidas para este gráfico.';

  @override
  String attChartPeak(String label, int count) {
    return 'Más atenciones: $label ($count)';
  }

  @override
  String attChartSemantics(String summary) {
    return 'Gráfico de atenciones. $summary';
  }

  @override
  String get attShiftMorning => 'Mañana (6h–12h)';

  @override
  String get attShiftAfternoon => 'Tarde (12h–18h)';

  @override
  String get attShiftNight => 'Noche (18h–6h)';

  @override
  String get csvDeviationPct => 'desvío vs media (%)';

  @override
  String get csvRatePerHour => 'atenciones por hora (ventana de actuación)';

  @override
  String get csvIdlePct => 'ociosidad (%)';

  @override
  String get abandonTitle => 'Abandonos';

  @override
  String get abandonSubtitle =>
      'Quien entró y salió antes de ser atendido. Las bajas automáticas (expiración y cierre) no cuentan.';

  @override
  String abandonBand(int start, int end) {
    return '$start–$end min';
  }

  @override
  String abandonBandOpen(int start) {
    return '$start+ min';
  }

  @override
  String get abandonWaitTitle => 'Tasa por franja de espera';

  @override
  String get abandonWaitHint =>
      'Abandonos cada 10 min de espera, entre quienes llegaron a cada franja.';

  @override
  String abandonWaitEmpty(int min) {
    return 'Muestra insuficiente: cada franja necesita al menos $min personas para mostrar la tasa.';
  }

  @override
  String abandonBarSpoken(String band, int pct) {
    return '$band: $pct% cada 10 min';
  }

  @override
  String abandonBarNoData(String band) {
    return '$band: datos insuficientes';
  }

  @override
  String abandonInflectionFound(String band, int limit) {
    return 'Punto de inflexión: desde $band el abandono supera $limit% cada 10 min.';
  }

  @override
  String abandonInflectionNone(int limit) {
    return 'Ninguna franja supera el límite de $limit% cada 10 min.';
  }

  @override
  String get abandonEstimateTitle => 'Tasa por estimación mostrada';

  @override
  String get abandonEstimateHint =>
      'Porcentaje de abandono según la estimación que vio el cliente al entrar.';

  @override
  String get abandonEstimateEmpty =>
      'Aún no hay registros con la estimación mostrada al entrar. El historial anterior a la actualización que guarda la estimación no tiene este dato.';

  @override
  String abandonEstimateBarSpoken(String band, int pct) {
    return 'Estimación $band: $pct% abandonaron';
  }

  @override
  String abandonEstimateBarNoData(String band) {
    return 'Estimación $band: datos insuficientes';
  }

  @override
  String get estimateAccuracyTitle => 'Precisión de la estimación';

  @override
  String estimateAccuracyMean(String value, int samples) {
    return 'Espera real menos estimación: $value min en promedio ($samples atendidos)';
  }

  @override
  String estimateAccuracyAbs(String value) {
    return 'Error absoluto medio: $value min';
  }

  @override
  String get estimateAccuracyHint =>
      'Positivo: la espera fue mayor que la prometida.';

  @override
  String estimateAccuracyNone(int min) {
    return 'Muestra insuficiente: se necesitan $min atenciones con estimación guardada.';
  }

  @override
  String get abandonHourTitle => 'Abandono por hora de llegada';

  @override
  String get abandonHourRateLabel => 'Tasa';

  @override
  String get abandonHourCountLabel => 'Abandonos';

  @override
  String abandonHourEmpty(int min) {
    return 'Muestra insuficiente: cada hora necesita al menos $min personas para mostrar la tasa.';
  }

  @override
  String abandonHourPeak(String hour, int pct, int left, int total) {
    return 'Mayor tasa a las $hour: $pct% ($left de $total)';
  }

  @override
  String abandonHourSpoken(String hour, int pct, int left, int total) {
    return '$hour: $pct% abandonaron ($left de $total)';
  }

  @override
  String abandonHourNoRate(String hour, int left, int total) {
    return '$hour: $left de $total, tasa con datos insuficientes';
  }

  @override
  String get capacityCardTitle => 'Posible falta de capacidad';

  @override
  String capacityCardBody(String hours, int wait, int rate) {
    return 'En estos horarios la espera media es de $wait min o más y $rate% o más abandona: $hours. Considere reforzar la atención.';
  }

  @override
  String get capacityCardNone => 'Ningún horario crítico en el período';

  @override
  String get csvWaitBand => 'franja de espera (min)';

  @override
  String get csvEstimateBand => 'franja de estimación (min)';

  @override
  String get csvAtRisk => 'llegaron a la franja';

  @override
  String get csvAbandonRatePct => 'abandono (%)';

  @override
  String get csvAbandonPer10Pct => 'abandono cada 10 min (%)';

  @override
  String get csvInflection => 'punto de inflexión';

  @override
  String get csvCapacityHours => 'horas con señal de capacidad';

  @override
  String get csvEstimateErrorMin => 'error medio de la estimación (min)';

  @override
  String get csvEstimateAbsErrorMin =>
      'error absoluto medio de la estimación (min)';

  @override
  String get biNameAttendantThroughput => 'Atenciones por hora y turno';

  @override
  String get biWhatAttendantThroughput =>
      'Cuántas atenciones concluyó cada atendente, distribuidas por hora del día (0 a 23) y por turno (mañana 6h–12h, tarde 12h–18h, noche 18h–6h).';

  @override
  String get biHowAttendantThroughput =>
      'Cuenta las atenciones agrupadas por el instante en que terminaron (o fueron llamadas, si falta el término), convertido a la hora de São Paulo. Ausentes y abandonos no cuentan.';

  @override
  String get biDataAttendantThroughput =>
      'Resultado, hora de término, hora de la llamada y quién llamó.';

  @override
  String get biUseAttendantThroughput =>
      'Ver en qué horarios y turnos cada persona concentra el trabajo y dimensionar la escala.';

  @override
  String get biNameAttendantService => 'Tiempo medio de servicio';

  @override
  String get biWhatAttendantService =>
      'Cuánto tarda, en promedio, el atendente entre llamar al cliente y finalizar la atención.';

  @override
  String biHowAttendantService(int min) {
    return 'Promedio de (término − llamada) de los atendidos. Con menos de $min muestras válidas no se muestra el valor (—).';
  }

  @override
  String get biDataAttendantService =>
      'Hora de la llamada, hora de término y resultado “atendido”.';

  @override
  String get biUseAttendantService =>
      'Conocer el ritmo real de cada persona y ajustar el tiempo medio configurado en la fila.';

  @override
  String get biNameAttendantDeviation => 'Desvío contra la media';

  @override
  String get biWhatAttendantDeviation =>
      'Cuánto se aleja el tiempo medio del atendente del promedio de todos en el alcance seleccionado. Negativo significa más rápido.';

  @override
  String biHowAttendantDeviation(int min) {
    return '(promedio del atendente − promedio del alcance) ÷ promedio del alcance × 100. El promedio del alcance se pondera por muestras. Solo entran atendentes con al menos $min muestras; los demás muestran —.';
  }

  @override
  String get biDataAttendantDeviation =>
      'Tiempo de servicio de los atendidos de cada atendente.';

  @override
  String get biUseAttendantDeviation =>
      'Identificar quién se desvía del patrón, para capacitación o revisión del tiempo medio. No mide calidad: una atención más larga puede ser más compleja.';

  @override
  String get biNameAttendantRate =>
      'Atenciones por hora en la ventana de actuación';

  @override
  String get biWhatAttendantRate =>
      'El ritmo del atendente dentro de la ventana en que actuó en el día. Pausas e intervalos entre atenciones están dentro de la ventana; no son horas efectivamente trabajadas.';

  @override
  String biHowAttendantRate(int min, int window) {
    return 'Por día: atendidos ÷ horas entre la primera llamada y el último término. El día solo vale con $min o más atenciones y ventana de al menos $window min. El valor mostrado suma atenciones y horas de los días válidos.';
  }

  @override
  String get biDataAttendantRate =>
      'Hora de la llamada, hora de término, resultado y quién llamó.';

  @override
  String get biUseAttendantRate =>
      'Comparar productividad sin el sesgo de quien trabajó pocas horas.';

  @override
  String get biNameAttendantIdle => 'Ociosidad';

  @override
  String get biWhatAttendantIdle =>
      'Parte del tiempo en que el atendente estuvo parado habiendo gente esperando.';

  @override
  String biHowAttendantIdle(int cap, int min) {
    return 'Suma de los intervalos entre el fin de una atención y la llamada de la siguiente, ÷ tiempo observado en el día. El intervalo solo cuenta si el siguiente cliente ya estaba en la fila, es mayor que cero y menor o igual a $cap min (más se presume pausa) y ocurre el mismo día. Solo aparece con al menos $min atenciones concluidas.';
  }

  @override
  String get biDataAttendantIdle =>
      'Hora de entrada en la fila, de la llamada y del término. Es una aproximación: el historial no guarda el tamaño de la fila en cada instante.';

  @override
  String get biUseAttendantIdle =>
      'Encontrar tiempo perdido entre atenciones (cambio lento, distracción) separándolo de fila vacía.';

  @override
  String get biNameAbandonWait => 'Abandono por franja de espera';

  @override
  String get biWhatAbandonWait =>
      'De quienes esperaron al menos hasta cierto punto, la fracción que abandonó en esa franja.';

  @override
  String biHowAbandonWait(String bands, int min) {
    return 'Franjas de $bands min. En cada franja: quienes abandonaron en la franja ÷ personas que llegaron a ella (incluso quien esperó más y fue atendido). Las barras muestran la tasa cada 10 min (limitada a 100%; las franjas más estrechas que 5 min usan 5 min como divisor), para comparar franjas de distinto ancho. Una franja con menos de $min personas no muestra tasa.';
  }

  @override
  String get biDataAbandonWait =>
      'Resultado, hora de entrada, llamada y término, y motivo de salida. Las bajas del sistema (expirada o cerrada) quedan fuera. Quien sigue en la fila no aparece, así que esperas largas recientes pueden estar subrepresentadas.';

  @override
  String get biUseAbandonWait =>
      'Mostrar desde qué espera el cliente empieza a irse.';

  @override
  String get biNameAbandonInflection => 'Punto de inflexión';

  @override
  String get biWhatAbandonInflection =>
      'La primera franja de espera en que el abandono pasa de lo tolerable.';

  @override
  String biHowAbandonInflection(int limit) {
    return 'Primera franja, en orden creciente, con más de $limit% de abandono cada 10 minutos. Las franjas sin tasa (muestra insuficiente) se omiten. Si ninguna pasa, no hay punto de inflexión.';
  }

  @override
  String get biDataAbandonInflection => 'La misma tasa por franja de espera.';

  @override
  String get biUseAbandonInflection =>
      'Definir la meta de espera máxima y el texto de aviso al cliente.';

  @override
  String get biNameAbandonEstimate => 'Abandono por estimación mostrada';

  @override
  String get biWhatAbandonEstimate =>
      'La tasa de abandono separada por la estimación de espera que vio el cliente al entrar.';

  @override
  String biHowAbandonEstimate(String bands, int min) {
    return 'Agrupa por estimación ($bands min): quienes abandonaron ÷ total de personas que vieron esa estimación. Una franja con menos de $min personas no muestra tasa.';
  }

  @override
  String get biDataAbandonEstimate =>
      'Estimación guardada al entrar y resultado. Los registros anteriores a la actualización que guarda la estimación no tienen el campo y quedan fuera.';

  @override
  String get biUseAbandonEstimate =>
      'Saber si prometer una espera larga aleja clientes, y si conviene mostrar la estimación de otra forma.';

  @override
  String get biNameEstimateAccuracy => 'Precisión de la estimación';

  @override
  String get biWhatEstimateAccuracy =>
      'Cuánto se equivocó la estimación mostrada al cliente, en minutos.';

  @override
  String biHowEstimateAccuracy(int min) {
    return 'Promedio de (espera real − estimación) para atendidos y ausentes. Positivo: la espera fue mayor que la prometida. También muestra el error absoluto medio, que evita que errores positivos y negativos se anulen. Menos de $min muestras: no se calcula.';
  }

  @override
  String get biDataEstimateAccuracy =>
      'Estimación guardada al entrar, hora de entrada y de llamada. Los registros anteriores a la grabación de la estimación quedan fuera.';

  @override
  String get biUseEstimateAccuracy =>
      'Evaluar si el tiempo medio configurado refleja la realidad y cuándo ajustarlo.';

  @override
  String get biNameAbandonHour => 'Abandono por hora de llegada';

  @override
  String get biWhatAbandonHour =>
      'La tasa y la cantidad de abandonos según la hora en que la persona entró en la fila.';

  @override
  String biHowAbandonHour(int min) {
    return 'Agrupa por la hora de entrada (São Paulo). Tasa = quienes abandonaron ÷ (atendidos + ausentes + abandonos). Una hora con menos de $min personas no muestra tasa, pero aparece la cantidad.';
  }

  @override
  String get biDataAbandonHour =>
      'Resultado, hora de entrada, espera y motivo de salida. Las bajas del sistema quedan fuera.';

  @override
  String get biUseAbandonHour => 'Localizar los horarios pico problemáticos.';

  @override
  String get biNameCapacitySignal => 'Señal de capacidad';

  @override
  String get biWhatCapacitySignal =>
      'Las horas en que la fila parece subdimensionada.';

  @override
  String biHowCapacitySignal(int wait, int rate) {
    return 'Horas con espera media de $wait min o más y tasa de abandono de $rate% o más. Las horas sin tasa (muestra insuficiente) no entran.';
  }

  @override
  String get biDataCapacitySignal =>
      'El abandono por hora de llegada y la espera media de cada hora.';

  @override
  String get biUseCapacitySignal =>
      'Indicar dónde reforzar atendentes o ajustar horarios.';

  @override
  String abandonBarCounts(int left, int total) {
    return '$left de $total abandonaron';
  }

  @override
  String abandonScopeQueue(String name) {
    return 'Fila: $name (filtro de la sección Por atendente)';
  }

  @override
  String get goalsTitle => 'Metas de atención';

  @override
  String get goalsNone => 'Sin metas definidas';

  @override
  String goalsValueWait(int min) {
    return 'Espera hasta $min min';
  }

  @override
  String goalsValueService(int min) {
    return 'Atención hasta $min min';
  }

  @override
  String goalsValueTarget(int pct) {
    return 'objetivo $pct%';
  }

  @override
  String get goalsDialogHint =>
      'Defina el tiempo aceptable y la parte de las atenciones que debe cumplir la meta. Deje en blanco lo que no quiera medir.';

  @override
  String get goalsWaitLabel => 'Espera máxima (min)';

  @override
  String get goalsServiceLabel => 'Atención máxima (min)';

  @override
  String get goalsTargetLabel => 'Objetivo de cumplimiento (%)';

  @override
  String goalsTargetHint(int pct) {
    return 'Predeterminado $pct';
  }

  @override
  String goalsErrRange(int min, int max) {
    return 'Ingrese de $min a $max minutos.';
  }

  @override
  String goalsErrTarget(int min, int max) {
    return 'Ingrese de $min a $max%.';
  }

  @override
  String get goalsErrNone => 'Defina al menos una meta: espera o atención.';

  @override
  String get goalsRemove => 'Quitar metas';

  @override
  String get goalRiskTitle => 'Meta de espera en riesgo';

  @override
  String goalRiskBody(int waiting, int est, int goal) {
    return 'Con $waiting en la fila, la espera estimada es de $est min, por encima de la meta de $goal min.';
  }

  @override
  String get goalRiskAction =>
      'Sugerencia: llame a otro atendedor o abra otro mostrador.';

  @override
  String get goalsSectionTitle => 'Metas';

  @override
  String get goalsSectionSubtitle =>
      'Cumplimiento de las metas definidas en cada fila, en el período y alcance elegidos.';

  @override
  String goalsQueuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Metas de $count filas en el alcance',
      one: 'Meta de 1 fila en el alcance',
    );
    return '$_temp0';
  }

  @override
  String get goalsWaitCardTitle => 'Espera dentro de la meta';

  @override
  String get goalsServiceCardTitle => 'Atención dentro de la meta';

  @override
  String goalsTargetLine(int pct) {
    return 'Objetivo: $pct% dentro del límite';
  }

  @override
  String goalsCounts(int ok, int total) {
    return '$ok de $total dentro del límite';
  }

  @override
  String get goalsMet => 'Alcanzada';

  @override
  String get goalsNotMet => 'No alcanzada';

  @override
  String goalsSmallSample(int min) {
    return 'Muestra pequeña: menos de $min evaluados.';
  }

  @override
  String get goalsNoSamples =>
      'Sin atenciones en el período para evaluar esta meta.';

  @override
  String get goalsNotSet => 'Ninguna fila del alcance tiene esta meta.';

  @override
  String get goalsDailyTitle => 'Cumplimiento por día';

  @override
  String goalsDailySemantics(int days, int missed) {
    return '$days días evaluados, $missed por debajo del objetivo';
  }

  @override
  String get goalsMissedTitle => 'Períodos en que no se alcanzó la meta';

  @override
  String goalsMissedNone(int min) {
    return 'Ningún día u hora por debajo del objetivo con al menos $min evaluados.';
  }

  @override
  String get goalsKindWait => 'Espera';

  @override
  String get goalsKindService => 'Atención';

  @override
  String goalsMissedDayRow(
    String kind,
    String day,
    int pct,
    int ok,
    int total,
    int target,
  ) {
    return '$kind, $day: $pct% ($ok de $total), objetivo $target%';
  }

  @override
  String goalsMissedHoursRow(String kind, String hours) {
    return '$kind, horas por debajo del objetivo: $hours';
  }

  @override
  String goalsMissedMore(int count) {
    return 'y $count días más';
  }

  @override
  String goalsWorstWait(int over, String day) {
    return 'Mayor incumplimiento de espera: $over min sobre la meta, el $day.';
  }

  @override
  String goalsWorstService(int over, String day) {
    return 'Mayor incumplimiento de atención: $over min sobre la meta, el $day.';
  }

  @override
  String get goalsNoViolation => 'Ningún incumplimiento en el período.';

  @override
  String get goalsCtaTitle => 'Defina metas de atención';

  @override
  String get goalsCtaBody =>
      'Ninguna fila de este alcance tiene metas. Abra la fila, vaya a Configuración y use Metas de atención para seguir el cumplimiento aquí.';

  @override
  String get staffTitle => 'Planificación de equipo';

  @override
  String get staffSubtitle =>
      'Cuántos atendedores exige cada día y hora, comparado con quién atendió realmente.';

  @override
  String staffServiceTime(String min, int samples) {
    return 'Tiempo medio de atención: $min min ($samples atenciones)';
  }

  @override
  String staffServiceNone(int min) {
    return 'Tiempo medio no disponible: se necesitan al menos $min atenciones concluidas.';
  }

  @override
  String staffOccupancy(int pct) {
    return 'Ocupación objetivo: $pct%';
  }

  @override
  String staffCoverage(int days) {
    return 'Base: $days días con datos';
  }

  @override
  String get staffModeRequired => 'Recomendado';

  @override
  String get staffModeObserved => 'Observado';

  @override
  String get staffModeGap => 'Diferencia';

  @override
  String get staffGridTitle => 'Atendedores por día y hora';

  @override
  String staffHintRequired(int pct) {
    return 'Atendedores recomendados para absorber la demanda media, con ocupación objetivo de $pct%.';
  }

  @override
  String get staffHintObserved =>
      'Promedio de atendedores distintos que atendieron en cada día y hora.';

  @override
  String get staffHintGap =>
      'Recomendado menos observado. Positivo: falta gente. Negativo: holgura.';

  @override
  String get staffLegendDeficit => 'Falta';

  @override
  String get staffLegendOk => 'Equilibrado';

  @override
  String get staffLegendSurplus => 'Holgura';

  @override
  String staffCellSpoken(
    String day,
    String hour,
    int required,
    String observed,
  ) {
    return '$day $hour: recomendado $required, observado $observed';
  }

  @override
  String staffGridSpoken(String mode, String top) {
    return 'Cuadrícula de atendedores por día y hora, modo $mode. $top';
  }

  @override
  String get staffTopTitle => 'Mayores déficits';

  @override
  String staffTopRow(String day, String hour, int required, String observed) {
    return '$day $hour: necesita $required, tiene $observed';
  }

  @override
  String get staffTopNone =>
      'Ningún déficit: el equipo observado cubre la demanda recomendada.';

  @override
  String get staffNoData =>
      'Sin llegadas en el período para dimensionar el equipo.';

  @override
  String get staffSeasonTitle => 'Volumen semanal y estacionalidad';

  @override
  String staffSeasonInsufficient(int need, int have) {
    return 'Datos insuficientes: se necesitan al menos $need semanas completas con datos (hay $have).';
  }

  @override
  String staffTrendUp(String pct) {
    return 'Tendencia al alza: cerca de +$pct% por semana.';
  }

  @override
  String staffTrendDown(String pct) {
    return 'Tendencia a la baja: cerca de $pct% por semana.';
  }

  @override
  String staffTrendStable(int pct) {
    return 'Volumen estable: variación inferior a $pct% por semana.';
  }

  @override
  String staffWeekSpoken(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count llegadas',
      one: '1 llegada',
    );
    return 'Semana del $date: $_temp0';
  }

  @override
  String get staffRecurringTitle => 'Patrón recurrente';

  @override
  String staffRecurringRow(String day, String hour, int weeks, int total) {
    return '$day $hour: entre las más llenas en $weeks de $total semanas';
  }

  @override
  String staffRecurringNone(int pct) {
    return 'Ninguna hora se repite entre las más llenas en al menos $pct% de las semanas.';
  }

  @override
  String get csvGoalIndicator => 'indicador';

  @override
  String get csvEvaluated => 'evaluados';

  @override
  String get csvWithinLimit => 'dentro del límite';

  @override
  String get csvPctWithinLimit => '% dentro del límite';

  @override
  String get csvTargetPct => 'objetivo %';

  @override
  String get csvGoalMet => 'meta alcanzada';

  @override
  String get csvWorstOverMin => 'mayor incumplimiento (min)';

  @override
  String get csvWorstDay => 'día del mayor incumplimiento';

  @override
  String get csvMissedDays => 'días por debajo del objetivo';

  @override
  String get csvMissedHours => 'horas por debajo del objetivo';

  @override
  String get csvArrivalsPerHour => 'llegadas por hora';

  @override
  String get csvRequiredStaff => 'atendedores recomendados';

  @override
  String get csvObservedStaff => 'atendedores observados';

  @override
  String get csvGapStaff => 'diferencia';

  @override
  String get csvWeekStart => 'inicio de la semana';

  @override
  String get csvTrendPct => 'tendencia (% del promedio por semana)';

  @override
  String get csvRecurringWeeks => 'semanas entre las más llenas';

  @override
  String get csvOccupancyPct => 'ocupación objetivo %';

  @override
  String get csvCoverageDays => 'días con datos';

  @override
  String get biNameGoalWait => 'Espera dentro de la meta';

  @override
  String get biWhatGoalWait =>
      'La parte de las atenciones en que la persona esperó hasta el límite de espera definido en la fila.';

  @override
  String biHowGoalWait(int min) {
    return 'Compara la espera (llamada menos entrada) de cada atendido y no presentado con la meta de espera. Quien se fue solo cuenta si esperó más que la meta, como incumplimiento; irse por debajo de la meta y las remociones del sistema quedan fuera. Porcentaje = dentro del límite ÷ evaluados. La meta se alcanza cuando el porcentaje llega al objetivo (predeterminado 80%). Con varias filas, cada persona se compara con la meta de su propia fila y el objetivo mostrado es el promedio ponderado por evaluados. Por debajo de $min evaluados, el resultado se marca como muestra pequeña.';
  }

  @override
  String get biDataGoalWait =>
      'Resultado, horas de entrada, de llamada y de salida (abandono) y las metas de la fila. Sin teléfono.';

  @override
  String get biUseGoalWait =>
      'Saber si el servicio está dentro del plazo prometido y cuándo falla.';

  @override
  String get biNameGoalService => 'Atención dentro de la meta';

  @override
  String get biWhatGoalService =>
      'La parte de las atenciones concluidas que duró hasta el tiempo máximo definido en la fila.';

  @override
  String biHowGoalService(int min) {
    return 'Solo atenciones concluidas (atendidos). Compara la duración (fin menos llamada) con la meta de atención. Porcentaje = dentro del límite ÷ evaluados; la meta se alcanza cuando llega al objetivo. Los no presentados y los abandonos no cuentan. Por debajo de $min evaluados, el resultado se marca como muestra pequeña.';
  }

  @override
  String get biDataGoalService =>
      'Resultado, horas de llamada y de término y las metas de la fila.';

  @override
  String get biUseGoalService =>
      'Verificar si las atenciones caben en el tiempo esperado y encontrar días y horas lentos.';

  @override
  String get biNameGoalMissed => 'Períodos en que no se alcanzó la meta';

  @override
  String get biWhatGoalMissed =>
      'Días y horas del día en que el cumplimiento quedó por debajo del objetivo, y el mayor incumplimiento.';

  @override
  String biHowGoalMissed(int min) {
    return 'Agrupa los evaluados por día y por hora del día (hora de São Paulo). Lista los días y horas con al menos $min evaluados y porcentaje por debajo del objetivo. El mayor incumplimiento es el mayor exceso, en minutos, sobre el límite de espera o de atención. Los días y horas con menos evaluados no se listan.';
  }

  @override
  String get biDataGoalMissed =>
      'Los mismos de los indicadores de espera y de atención dentro de la meta.';

  @override
  String get biUseGoalMissed =>
      'Encontrar cuándo la meta falla de forma recurrente y reforzar el equipo en esos períodos.';

  @override
  String get biNameStaffingService => 'Tiempo medio de atención';

  @override
  String get biWhatStaffingService =>
      'La duración media de las atenciones concluidas, usada para estimar cuántos atendedores se necesitan.';

  @override
  String biHowStaffingService(int min) {
    return 'Promedio de fin menos llamada de las atenciones concluidas (atendidos) del alcance y período. Con menos de $min atenciones no se calcula y la recomendación de atendedores no está disponible.';
  }

  @override
  String get biDataStaffingService =>
      'Resultado, horas de llamada y de término.';

  @override
  String get biUseStaffingService =>
      'Servir de base para el cálculo de atendedores recomendados.';

  @override
  String get biNameStaffingRequired => 'Atendedores recomendados';

  @override
  String get biWhatStaffingRequired =>
      'Cuántos atendedores exige cada día de la semana y hora para absorber la demanda media.';

  @override
  String biHowStaffingRequired(int pct) {
    return 'Llegadas por hora = llegadas en ese día de la semana y hora ÷ número de veces que ese día ocurre entre el primer y el último día con datos (incluye abandonos y no presentados). Recomendados = redondear hacia arriba (llegadas por hora × tiempo medio de atención en horas ÷ ocupación objetivo de $pct%). No disponible sin tiempo medio de atención.';
  }

  @override
  String get biDataStaffingRequired =>
      'Hora de entrada de todas las personas, resultado, horas de llamada y de término.';

  @override
  String get biUseStaffingRequired =>
      'Armar turnos: ver en qué días y horas el equipo necesita ser mayor.';

  @override
  String get biNameStaffingObserved => 'Atendedores observados';

  @override
  String get biWhatStaffingObserved =>
      'Cuántos atendedores distintos atendieron realmente en cada día de la semana y hora.';

  @override
  String get biHowStaffingObserved =>
      'Para cada fecha y hora, cuenta los atendedores distintos con una atención en curso, de la llamada al fin (las atenciones largas cuentan en todas las horas que atraviesan). Suma por día de la semana y hora y divide por el mismo número de ocurrencias del día usado en las llegadas. El dueño y los registros sin atendedor cuentan como un atendedor.';

  @override
  String get biDataStaffingObserved =>
      'Atendedor, horas de llamada y de término, resultado (atendido o no presentado).';

  @override
  String get biUseStaffingObserved =>
      'Comparar el equipo que realmente actuó con el recomendado.';

  @override
  String get biNameStaffingGap => 'Déficit y holgura';

  @override
  String get biWhatStaffingGap =>
      'La diferencia entre atendedores recomendados y observados en cada día y hora.';

  @override
  String biHowStaffingGap(int n) {
    return 'Diferencia = recomendados menos observados. Positivo es déficit (falta gente); negativo es holgura. La lista muestra las $n mayores diferencias positivas, desempatando por recomendados, día y hora.';
  }

  @override
  String get biDataStaffingGap =>
      'Los mismos de los atendedores recomendados y observados.';

  @override
  String get biUseStaffingGap =>
      'Priorizar dónde reforzar el equipo y dónde sobra capacidad.';

  @override
  String get biNameSeasonVolume => 'Volumen semanal y tendencia';

  @override
  String get biWhatSeasonVolume =>
      'Cuántas personas entraron en la fila en cada una de las últimas semanas y hacia dónde va el volumen.';

  @override
  String biHowSeasonVolume(int weeks, int band, int min) {
    return 'Cuenta las llegadas (incluye abandonos y no presentados) por semana, de lunes a domingo (hora de São Paulo), en las últimas $weeks semanas completas, desde la primera semana con datos; la semana en curso queda fuera. La tendencia es la pendiente de una recta ajustada a los volúmenes semanales, en % del promedio semanal por semana; por debajo de $band% se considera estable. Con menos de $min semanas, muestra datos insuficientes.';
  }

  @override
  String get biDataSeasonVolume =>
      'Hora de entrada de todas las personas. Usa todo el historial cargado del alcance, no solo el período elegido.';

  @override
  String get biUseSeasonVolume =>
      'Planificar equipo y espacio para los próximos períodos.';

  @override
  String get biNameSeasonPattern => 'Patrón recurrente';

  @override
  String get biWhatSeasonPattern =>
      'Días de la semana y horas que se repiten entre los más movidos, semana tras semana.';

  @override
  String biHowSeasonPattern(int top, int pct, int min) {
    return 'En cada semana observada, toma las $top celdas (día de la semana × hora) con más llegadas. Una celda es recurrente cuando aparece en ese grupo en al menos $pct% de las semanas observadas. Exige al menos $min semanas.';
  }

  @override
  String get biDataSeasonPattern => 'Hora de entrada de todas las personas.';

  @override
  String get biUseSeasonPattern =>
      'Saber qué horarios están siempre movidos, y no por casualidad.';
}
