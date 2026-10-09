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
    return '$count horarios';
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
}
