// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Voltar';

  @override
  String get create => 'Criar';

  @override
  String get remove => 'Remover';

  @override
  String get delete => 'Excluir';

  @override
  String get copy => 'Copiar';

  @override
  String get share => 'Compartilhar';

  @override
  String get print => 'Imprimir';

  @override
  String get genericActionError =>
      'Não foi possível concluir a ação. Tente novamente.';

  @override
  String get authInvalidCredentials => 'E-mail ou senha incorretos.';

  @override
  String get authInvalidEmail => 'E-mail inválido.';

  @override
  String get authEmailInUse => 'Já existe uma conta com este e-mail.';

  @override
  String get authWeakPassword => 'Senha fraca. Use pelo menos 6 caracteres.';

  @override
  String get authUserDisabled => 'Esta conta foi desativada.';

  @override
  String get authTooManyRequests =>
      'Muitas tentativas. Aguarde alguns minutos e tente de novo.';

  @override
  String get authNetworkError =>
      'Sem conexão. Verifique a internet e tente de novo.';

  @override
  String get authGeneric => 'Não foi possível entrar. Tente novamente.';

  @override
  String get loginTagline => 'Sistema de filas inteligente';

  @override
  String get nameLabel => 'Nome';

  @override
  String get nameHint => 'Seu nome';

  @override
  String get nameRequired => 'Informe seu nome';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'voce@email.com';

  @override
  String get emailRequired => 'Informe o email';

  @override
  String get passwordLabel => 'Senha';

  @override
  String get passwordMin => 'Mínimo 6 caracteres';

  @override
  String get signIn => 'Entrar';

  @override
  String get createAccount => 'Criar conta';

  @override
  String get orSeparator => 'ou';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get haveAccountSignIn => 'Já tem conta? Entrar';

  @override
  String get accountTitle => 'Minha conta';

  @override
  String businessLine(String business) {
    return 'Negócio: $business';
  }

  @override
  String get queuesCreated => 'Filas criadas';

  @override
  String get memberSince => 'Membro desde';

  @override
  String get signOut => 'Sair da conta';

  @override
  String get signOutError => 'Não foi possível sair da conta.';

  @override
  String get deleteAccountTitle => 'Excluir minha conta';

  @override
  String get deleteAccountZone => 'Zona de risco';

  @override
  String get deleteAccountSubtitle =>
      'Apaga sua conta, suas filas, históricos, avaliações e dispositivos. Não dá para desfazer.';

  @override
  String get deleteAccountWarning =>
      'Todas as suas filas, o histórico de atendimentos, as avaliações, os grupos e a sua conta serão apagados de forma permanente. Quem está em uma fila sua perde a senha. Se você é operador de filas de outras pessoas, apenas o seu vínculo é removido.';

  @override
  String get deleteAccountConfirmLabel =>
      'Digite EXCLUIR ou o seu e-mail para confirmar';

  @override
  String get deleteAccountPasswordLabel => 'Senha atual';

  @override
  String get deleteAccountGoogleHint =>
      'Você vai confirmar sua identidade com o Google antes de excluir.';

  @override
  String get deleteAccountConfirmButton => 'Excluir definitivamente';

  @override
  String get deleteAccountProgress =>
      'Excluindo seus dados. Isso pode levar alguns instantes.';

  @override
  String get deleteAccountReauthFailed =>
      'Não foi possível confirmar sua identidade. Confira a senha e tente de novo.';

  @override
  String get deleteAccountError =>
      'A exclusão não terminou. Parte dos dados pode já ter sido apagada. Tente novamente para concluir.';

  @override
  String get deleteAccountRetry => 'Tentar novamente';

  @override
  String get deleteAccountRecentLogin =>
      'Por segurança, confirme sua identidade de novo para concluir a exclusão.';

  @override
  String get appearance => 'Aparência';

  @override
  String get systemOption => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get newQueue => 'Nova fila';

  @override
  String get queueNameLabel => 'Nome da fila *';

  @override
  String get queueNameHint => 'Ex: Atendimento balcão';

  @override
  String get queueNameRequired => 'Informe o nome';

  @override
  String get descriptionLabel => 'Descrição (opcional)';

  @override
  String get descriptionHint => 'Descreva o propósito da fila...';

  @override
  String get avgServiceLabel => 'Tempo médio de atendimento (minutos)';

  @override
  String get invalidNumber => 'Informe um número válido';

  @override
  String get createQueue => 'Criar fila';

  @override
  String get myQueues => 'Minhas filas';

  @override
  String get joinAsOperator => 'Entrar como operador';

  @override
  String get tourHomeFabTitle => 'Crie sua primeira fila';

  @override
  String get tourHomeFabBody =>
      'Toque no + para criar uma fila e gerar o QR code.';

  @override
  String get tourHomeQueueTitle => 'Abra sua fila';

  @override
  String get tourHomeQueueBody =>
      'Toque no cartão para abrir o painel e chamar as pessoas. Pause ou mostre o QR code pelos atalhos do cartão.';

  @override
  String get emptyQueuesTitle => 'Nenhuma fila ainda';

  @override
  String get emptyQueuesBody =>
      'Crie sua primeira fila ou entre como operador com um código de convite';

  @override
  String get sectionOwner => 'SOU DONO';

  @override
  String get sectionOperator => 'SOU OPERADOR';

  @override
  String get sectionRequests => 'PEDIDOS DE OPERADOR';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas esperando',
      one: '$count pessoa esperando',
    );
    return '$_temp0';
  }

  @override
  String createdOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Criada em $dateString';
  }

  @override
  String get youAreOperator => 'Você é operador desta fila';

  @override
  String get requestRemovedStatus => 'Você foi removido desta fila';

  @override
  String get requestRejectedStatus => 'Pedido recusado';

  @override
  String get awaitingApproval => 'Aguardando aprovação';

  @override
  String get dismiss => 'Dispensar';

  @override
  String get statusOpen => 'Aberta';

  @override
  String get statusPaused => 'Pausada';

  @override
  String get statusClosed => 'Fechada';

  @override
  String get joinOperatorIntro =>
      'Peça o código de convite ao dono da fila. Depois de enviar, o dono precisa aprovar seu acesso.';

  @override
  String get inviteCodeLabel => 'Código de convite';

  @override
  String get inviteCodeHint => 'Ex: K7M2QX';

  @override
  String get inviteCodeLength => 'O código tem 6 caracteres';

  @override
  String get sendRequest => 'Enviar pedido';

  @override
  String get sendRequestError =>
      'Não foi possível enviar o pedido. Tente novamente.';

  @override
  String get cancelRequestError =>
      'Não foi possível cancelar. Tente novamente.';

  @override
  String get pendingBody =>
      'O dono da fila precisa aprovar seu pedido. Esta tela atualiza sozinha.';

  @override
  String get requestApproved => 'Pedido aprovado';

  @override
  String get approvedBody => 'Você já pode atender esta fila.';

  @override
  String get requestRejected => 'Pedido recusado';

  @override
  String get rejectedBody => 'O dono da fila recusou seu pedido.';

  @override
  String get removedTitle => 'Você foi removido';

  @override
  String get removedBody => 'O dono da fila removeu seu acesso de operador.';

  @override
  String get requestNotFound => 'Pedido não encontrado';

  @override
  String get requestNotFoundBody => 'O pedido foi cancelado ou removido.';

  @override
  String get openQueue => 'Abrir fila';

  @override
  String get cancelRequest => 'Cancelar pedido';

  @override
  String get inviteGenerateFailed => 'Não foi possível gerar um código.';

  @override
  String get inviteInvalid => 'Código inválido.';

  @override
  String get inviteInvalidOrRevoked => 'Código inválido ou revogado.';

  @override
  String get inviteExpired => 'Código expirado. Peça um novo ao dono.';

  @override
  String get inviteOwnQueue => 'Você já é o dono desta fila.';

  @override
  String get operatorsTitle => 'Operadores';

  @override
  String get pendingRequestsSection => 'PEDIDOS PENDENTES';

  @override
  String get activeOperatorsSection => 'OPERADORES ATIVOS';

  @override
  String get noPendingRequests => 'Nenhum pedido pendente';

  @override
  String get noOperatorsYet => 'Nenhum operador ainda';

  @override
  String get inviteExplain =>
      'Quem receber o código pede acesso pelo app. Você aprova cada pedido.';

  @override
  String get noExpiration => 'Sem expiração';

  @override
  String validUntil(String date) {
    return 'Válido até $date';
  }

  @override
  String get revokeCode => 'Revogar código';

  @override
  String get previousCodeExpired => 'O código anterior expirou.';

  @override
  String get validity => 'Validade';

  @override
  String get validityHour => '1 hora';

  @override
  String get validityDay => '24 horas';

  @override
  String get validityWeek => '7 dias';

  @override
  String get generateNewCode => 'Gerar novo código';

  @override
  String get generateCode => 'Gerar código';

  @override
  String get reject => 'Recusar';

  @override
  String get approve => 'Aprovar';

  @override
  String get removeOperatorTooltip => 'Remover operador';

  @override
  String get removeOperatorTitle => 'Remover operador?';

  @override
  String removeOperatorBody(String name) {
    return '$name perde o acesso à fila. Atendimentos já chamados por essa pessoa continuam na fila.';
  }

  @override
  String get codeCopied => 'Código copiado!';

  @override
  String shareCodeText(String queue, String code) {
    return 'Código para atender a fila \"$queue\" no Qio: $code\nAbra o app Qio > Entrar como operador.';
  }

  @override
  String get tourPanelQrTitle => 'Compartilhe o QR code';

  @override
  String get tourPanelQrBody =>
      'Seus clientes escaneiam para entrar na fila, sem instalar nada.';

  @override
  String get tourPanelCallTitle => 'Chame o próximo';

  @override
  String get tourPanelCallBody =>
      'Toque aqui para chamar a próxima pessoa da fila.';

  @override
  String newPersonInQueue(String name) {
    return 'Nova pessoa na fila: $name';
  }

  @override
  String newPeopleInQueue(int count) {
    return '$count novas pessoas na fila';
  }

  @override
  String get syncError => 'Não foi possível sincronizar a fila. Tente reabrir.';

  @override
  String get accessEndedTitle => 'Acesso encerrado';

  @override
  String get accessEndedBody =>
      'Você não é mais operador desta fila. O dono removeu seu acesso ou a fila foi excluída.';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get reopen => 'Reabrir';

  @override
  String get pause => 'Pausar';

  @override
  String get close => 'Fechar';

  @override
  String get queueClosedTitle => 'Fila fechada';

  @override
  String get noServiceInProgress => 'Nenhum atendimento em andamento';

  @override
  String get closedOwnerHint =>
      'A fila está fechada. Você pode reabri-la ou excluí-la.';

  @override
  String get closedOperatorHint =>
      'A fila está fechada. Aguarde o dono reabrir.';

  @override
  String get servingByOthers => 'EM ATENDIMENTO POR OUTROS';

  @override
  String get finishService => 'Finalizar atendimento';

  @override
  String get served => 'Atendido';

  @override
  String get noShow => 'Não compareceu';

  @override
  String get upNext => 'PRÓXIMOS NA FILA';

  @override
  String get nobodyInQueue => 'Ninguém na fila';

  @override
  String get deleteQueue => 'Excluir fila';

  @override
  String get callNext => 'Chamar próximo';

  @override
  String get operatorsAndInvites => 'Operadores e convites';

  @override
  String get qrSemantics => 'QR code para entrar na fila';

  @override
  String get scanToJoin => 'Escaneie para entrar na fila';

  @override
  String get copyLinkSemantics => 'Copiar link da fila';

  @override
  String get copyLink => 'Copiar link';

  @override
  String get printablePoster => 'Cartaz para impressão';

  @override
  String get linkCopied => 'Link copiado!';

  @override
  String get deleteQueueTitle => 'Excluir fila?';

  @override
  String get deleteQueueBody =>
      'Essa ação é permanente. A fila e todo o histórico de atendimentos serão apagados.';

  @override
  String get nobodyCalled => 'Ninguém chamado';

  @override
  String get callNextHint => 'Toque em \"Chamar próximo\" para começar';

  @override
  String get callingNow => 'CHAMANDO AGORA';

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
  String get nothingToExport => 'Nada para exportar neste filtro.';

  @override
  String get exportError => 'Não foi possível exportar o histórico.';

  @override
  String get loadHistoryError =>
      'Não foi possível carregar o histórico. Tente novamente.';

  @override
  String get noHistoryYet => 'Nenhum atendimento ainda';

  @override
  String get noHistoryInFilter => 'Nenhum atendimento neste filtro';

  @override
  String get filterAll => 'Todos';

  @override
  String get periodToday => 'Hoje';

  @override
  String get period7Days => '7 dias';

  @override
  String get periodAll => 'Tudo';

  @override
  String get servedPlural => 'Atendidos';

  @override
  String get noShowPlural => 'Não compareceram';

  @override
  String get leftPlural => 'Desistiram';

  @override
  String get avgWait => 'Espera média';

  @override
  String get avgService => 'Atendimento médio';

  @override
  String get avgRating => 'Avaliação média';

  @override
  String get resultLeft => 'Desistiu';

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
  String get csvName => 'nome';

  @override
  String get csvPhone => 'telefone';

  @override
  String get csvResult => 'resultado';

  @override
  String get csvEntered => 'entrada';

  @override
  String get csvCalled => 'chamado';

  @override
  String get csvFinished => 'finalizado';

  @override
  String get pdfTitle => 'Qio - Histórico de atendimentos';

  @override
  String pdfGeneratedAt(String date) {
    return 'Gerado em $date';
  }

  @override
  String get pdfTotal => 'Total';

  @override
  String get pdfNoRecords => 'Nenhum atendimento no período.';

  @override
  String get colTicket => 'Ticket';

  @override
  String get colName => 'Nome';

  @override
  String get colPhone => 'Telefone';

  @override
  String get colResult => 'Resultado';

  @override
  String get colEntered => 'Entrada';

  @override
  String get colCalled => 'Chamado';

  @override
  String get colFinished => 'Finalizado';

  @override
  String get posterTitle => 'Cartaz do QR';

  @override
  String get qrColor => 'COR DO QR';

  @override
  String get qrColorBlue => 'Azul';

  @override
  String get qrColorBlack => 'Preto';

  @override
  String get qrColorDarkGreen => 'Verde escuro';

  @override
  String get shareImage => 'Compartilhar imagem';

  @override
  String get shareImageError => 'Não foi possível compartilhar a imagem.';

  @override
  String get printPosterError => 'Não foi possível imprimir o cartaz.';

  @override
  String get skip => 'PULAR';

  @override
  String stepOf(int index, int total) {
    return '$index de $total';
  }

  @override
  String get tapToContinue => 'Toque para continuar';

  @override
  String avatarLabel(String name) {
    return 'Avatar: $name';
  }

  @override
  String get metricsTitle => 'Métricas';

  @override
  String get metricsTooltip => 'Métricas das filas';

  @override
  String get metricsTotal => 'Atendimentos';

  @override
  String get peakHoursTitle => 'Picos de demanda';

  @override
  String get peakHoursSubtitle => 'Pessoas que entraram por horário';

  @override
  String peakHoursTop(String hours) {
    return 'Horários mais cheios: $hours';
  }

  @override
  String get noPeakData => 'Sem dados no período';

  @override
  String get mostActiveQueues => 'Filas mais ativas';

  @override
  String queueActivityLine(int total, int rate) {
    return '$total atendimentos · $rate% não compareceram';
  }

  @override
  String get noMetricsData => 'Nenhum atendimento no período';

  @override
  String get loadMetricsError =>
      'Não foi possível carregar as métricas. Tente novamente.';

  @override
  String get noQueuesYet => 'Você ainda não tem filas';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get forgotPassword => 'Esqueci a senha';

  @override
  String get resetEmailRequired => 'Informe seu e-mail para recuperar a senha';

  @override
  String get resetEmailSent =>
      'Se houver uma conta com esse e-mail, enviamos um link para redefinir a senha.';

  @override
  String get showPassword => 'Mostrar senha';

  @override
  String get hidePassword => 'Ocultar senha';

  @override
  String get offlineBanner =>
      'Sem conexão. Os dados podem estar desatualizados.';

  @override
  String get loadErrorTitle => 'Algo deu errado';

  @override
  String get loadErrorBody =>
      'Não foi possível carregar seus dados. Verifique a conexão e tente de novo.';

  @override
  String get hapticsTitle => 'Vibração';

  @override
  String get hapticsSubtitle => 'Vibrar ao chamar, finalizar e confirmar ações';

  @override
  String get analyticsTitle => 'Ajudar a melhorar o Qio';

  @override
  String get analyticsSubtitle =>
      'Envia estatísticas anônimas de uso (sem nomes, telefones ou dados de clientes). Você pode desativar quando quiser.';

  @override
  String get nobodyInQueueHint =>
      'Quando alguém entrar pelo QR code, aparece aqui.';

  @override
  String get emptyHistoryHint => 'Os atendimentos finalizados aparecem aqui.';

  @override
  String get emptyMetricsHint =>
      'Escolha outro período ou aguarde os primeiros atendimentos.';

  @override
  String get discardTitle => 'Descartar alterações?';

  @override
  String get discardBody =>
      'Você já preencheu campos. Se sair agora, vai perder o que digitou.';

  @override
  String get keepEditing => 'Continuar editando';

  @override
  String get discard => 'Descartar';

  @override
  String get maxWaitingLabel => 'Limite de pessoas esperando (opcional)';

  @override
  String get maxWaitingHint => 'Sem limite';

  @override
  String get maxWaitingInvalid => 'Use um número de 1 a 1000';

  @override
  String get queueLimitTitle => 'Limite da fila';

  @override
  String get queueLimitNone => 'Sem limite de espera';

  @override
  String queueLimitValue(int max) {
    return 'Até $max pessoas esperando';
  }

  @override
  String get save => 'Salvar';

  @override
  String get pauseQueueTitle => 'Pausar a fila';

  @override
  String get closeQueueTitle => 'Fechar a fila';

  @override
  String get statusMessageLabel => 'Mensagem para os clientes (opcional)';

  @override
  String get statusSuggestionBack10 => 'Volto em 10 minutos';

  @override
  String get statusSuggestionBreak => 'Intervalo rápido';

  @override
  String get statusSuggestionClosedToday => 'Fila encerrada por hoje';

  @override
  String get resumeAtLabel => 'Previsão de retorno';

  @override
  String get resumeAtNone => 'Sem previsão';

  @override
  String get clear => 'Limpar';

  @override
  String waitingCounter(int count, int max) {
    return '$count/$max esperando';
  }

  @override
  String get callAgain => 'Chamar de novo';

  @override
  String get callNow => 'Chamar agora';

  @override
  String get moveToEnd => 'Mover para o fim';

  @override
  String get moreActions => 'Mais ações';

  @override
  String calledTimes(int count) {
    return 'Chamado ${count}x';
  }

  @override
  String get callResent => 'Chamada reenviada';

  @override
  String movedToEnd(String name) {
    return '$name foi para o fim da fila';
  }

  @override
  String get entryUnavailable => 'Esta pessoa já não está aguardando';

  @override
  String get scheduleTitle => 'Horário de funcionamento';

  @override
  String get scheduleOff => 'Desligado';

  @override
  String scheduleHours(String days, String open, String close) {
    return '$days · $open–$close';
  }

  @override
  String get scheduleEnabled => 'Abrir e fechar automaticamente';

  @override
  String get scheduleDays => 'Dias';

  @override
  String get scheduleOpens => 'Abre';

  @override
  String get scheduleCloses => 'Fecha';

  @override
  String get scheduleInvalidDays => 'Escolha ao menos um dia';

  @override
  String get scheduleInvalidTime =>
      'Abertura e fechamento devem ser diferentes';

  @override
  String get scheduleNote =>
      'Horário de Brasília. Se você abrir, pausar ou fechar na mão, vale até a próxima abertura ou fechamento do horário.';

  @override
  String get linkForCustomers =>
      'Este link é para clientes. Abrindo no navegador.';

  @override
  String get brandTitle => 'Identidade da fila';

  @override
  String get brandSubtitle => 'Cor e logo na página do cliente';

  @override
  String get brandColorLabel => 'Cor';

  @override
  String get brandLogoLabel => 'Logo';

  @override
  String get brandChooseImage => 'Escolher imagem';

  @override
  String get brandError =>
      'Não foi possível salvar. Verifique a conexão e tente de novo.';

  @override
  String get pushTitle => 'Avisos de novas entradas';

  @override
  String get pushSubtitle =>
      'Notificar quando alguém entrar na fila, mesmo com o app fechado';

  @override
  String get pushPromptTitle => 'Receber avisos?';

  @override
  String get pushPromptBody =>
      'Avisamos quando alguém entrar em uma das suas filas, mesmo com o app fechado. Você pode mudar isso depois em Minha conta.';

  @override
  String get pushPromptNotNow => 'Agora não';

  @override
  String get pushPromptEnable => 'Ativar';

  @override
  String get pushDenied =>
      'Permissão negada. Ative as notificações nas configurações do sistema.';

  @override
  String get byOperatorTitle => 'Por atendente';

  @override
  String get operatorFilterAll => 'Todas as filas';

  @override
  String get ownerAttendant => 'Dono';

  @override
  String get formerOperator => 'ex-operador';

  @override
  String get noOperatorData => 'Nenhum atendimento por atendente no período';

  @override
  String historyTruncatedWarning(int limit) {
    return 'Mostrando só os $limit registros mais recentes de uma fila; os números podem estar incompletos.';
  }

  @override
  String operatorCountsLine(int served, int noShow) {
    return '$served atendidos · $noShow não compareceram';
  }

  @override
  String operatorDetailLine(String avg, String rating) {
    return 'Atendimento médio: $avg · Avaliação: $rating';
  }

  @override
  String get operatorFilterLabel => 'Filtrar por fila';

  @override
  String get metricsPdfTitle => 'Qio - Métricas das filas';

  @override
  String get csvPeriod => 'período';

  @override
  String get csvScope => 'escopo por atendente';

  @override
  String get csvGeneratedAt => 'gerado em';

  @override
  String get csvMetric => 'métrica';

  @override
  String get csvValue => 'valor';

  @override
  String get csvHour => 'hora';

  @override
  String get csvEntries => 'entradas';

  @override
  String get csvPosition => 'posição';

  @override
  String get csvQueue => 'fila';

  @override
  String get csvTotal => 'total';

  @override
  String get csvServed => 'atendidos';

  @override
  String get csvNoShow => 'não compareceram';

  @override
  String get csvLeft => 'desistiram';

  @override
  String get csvNoShowRatePct => 'taxa de não comparecimento (%)';

  @override
  String get csvAvgWaitMin => 'espera média (min)';

  @override
  String get csvAvgServiceMin => 'atendimento médio (min)';

  @override
  String get csvAvgRating => 'nota média';

  @override
  String get csvRatingCount => 'qtd notas';

  @override
  String get csvAttendant => 'atendente';

  @override
  String get exportMetricsError => 'Não foi possível exportar as métricas.';

  @override
  String get groups => 'Grupos';

  @override
  String get groupNew => 'Novo grupo…';

  @override
  String get groupRename => 'Renomear grupo';

  @override
  String get groupDelete => 'Excluir grupo';

  @override
  String groupDeleteConfirm(String name) {
    return 'Excluir o grupo \"$name\"? As filas dele ficam sem grupo.';
  }

  @override
  String get groupNone => 'Sem grupo';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String groupLimitReached(int max) {
    return 'Limite de $max grupos atingido.';
  }

  @override
  String queueLimitReached(int max) {
    return 'Limite de $max filas atingido. Exclua uma fila para criar outra.';
  }

  @override
  String get groupLabel => 'Grupo';

  @override
  String get groupsEmpty =>
      'Nenhum grupo ainda. Crie um para organizar suas filas.';

  @override
  String get groupPermissionDenied =>
      'Sem permissão para alterar grupos. Atualize o app e tente de novo.';

  @override
  String get metricsScopeLabel => 'Escopo das métricas';

  @override
  String get metricsScopeAll => 'Todas as filas';

  @override
  String metricsScopeGroup(String name) {
    return 'Grupo: $name';
  }

  @override
  String metricsScopeQueue(String name) {
    return 'Fila: $name';
  }

  @override
  String get groupCompareTitle => 'Comparativo entre filas do grupo';

  @override
  String groupCompareLine(int total, String wait, int rate, String rating) {
    return '$total atendimentos · espera $wait · $rate% não compareceram · nota $rating';
  }

  @override
  String get csvDataScope => 'escopo das métricas';

  @override
  String get groupsUnavailable =>
      'Grupos indisponíveis. Atualize o app ou as regras do Firestore.';

  @override
  String get alertsTitle => 'Alertas operacionais';

  @override
  String get alertsEnable => 'Receber alertas desta fila';

  @override
  String get alertsWaitLimit => 'Espera estimada acima de';

  @override
  String get alertsNoShowLimit => 'Não comparecimento hoje a partir de';

  @override
  String get alertsIdleLimit => 'Fila parada com gente esperando por mais de';

  @override
  String get alertsCooldown => 'Intervalo mínimo entre alertas';

  @override
  String get alertsPushOff =>
      'As notificações estão desativadas. Ative-as para receber os alertas.';

  @override
  String get alertsOff => 'Desligado';

  @override
  String alertsActive(int count) {
    return '$count regras ativas';
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
  String get alertsNoRule => 'Ative ao menos uma regra para receber alertas.';

  @override
  String get alertsNotify => 'Receber alertas nesta conta';

  @override
  String get waitDistributionTitle => 'Espera e chamadas';

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
  String get waitBucketOver30 => 'Mais de 30 min';

  @override
  String get recallsTitle => 'Re-chamadas';

  @override
  String get skipsTitle => 'Movidos ao fim';

  @override
  String recallsStat(int entries, int total, int pct, int recalls) {
    return '$entries entradas de $total ($pct%) · $recalls re-chamadas';
  }

  @override
  String skipsStat(int entries, int total, int skips) {
    return '$entries entradas de $total · $skips movidos ao fim';
  }

  @override
  String get csvWaitSamples => 'amostras de espera';

  @override
  String get csvMedianWaitMin => 'mediana (min)';

  @override
  String get csvP90WaitMin => 'P90 (min)';

  @override
  String get csvWaitRange => 'faixa de espera';

  @override
  String get csvCalledEntries => 'entradas chamadas';

  @override
  String get csvRecallsTotal => 're-chamadas';

  @override
  String get csvRecalledEntries => 'entradas com re-chamada';

  @override
  String get csvRecallRatePct => 'entradas com re-chamada sobre chamadas (%)';

  @override
  String get csvSkipsTotal => 'movidos ao fim';

  @override
  String get csvSkippedEntries => 'entradas movidas ao fim';

  @override
  String get p90Insufficient => 'amostras insuficientes';

  @override
  String get weekdayDemandTitle => 'Dias de maior movimento';

  @override
  String get heatmapTitle => 'Mapa de calor: dia × hora';

  @override
  String demandPeakSummary(String day, String from, String to) {
    return 'Pico: $day, $from–$to';
  }

  @override
  String heatmapCellSemantics(String day, String hour, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chegadas',
      one: '1 chegada',
    );
    return '$day, $hour: $_temp0';
  }

  @override
  String get csvWeekday => 'dia';

  @override
  String get csvArrivals => 'chegadas';

  @override
  String get heatmapLegendLess => 'menos';

  @override
  String get heatmapLegendMore => 'mais';

  @override
  String weekdayChartSemantics(String details) {
    return 'Chegadas por dia: $details';
  }

  @override
  String get period30Days => '30 dias';

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
  String get deltaSame => '= estável';

  @override
  String deltaPoints(String pp) {
    return '$pp p.p.';
  }

  @override
  String get deltaRose => 'subiu';

  @override
  String get deltaFell => 'caiu';

  @override
  String get deltaVsPrevious => 'vs. período anterior';

  @override
  String get trendTitle => 'Tendência diária';

  @override
  String get trendSeriesTotal => 'Atendimentos por dia';

  @override
  String get trendSeriesWait => 'Espera média';

  @override
  String get trendSeriesNoShow => 'Não comparecimento';

  @override
  String trendSummary(String avg, String peakDay) {
    return 'Média de $avg por dia, pico em $peakDay';
  }

  @override
  String get csvDate => 'data';

  @override
  String get csvCompareTitle => 'Comparativo com o período anterior';

  @override
  String get csvCurrent => 'atual';

  @override
  String get csvPrevious => 'anterior';

  @override
  String get csvDeltaPct => 'variação (%)';

  @override
  String get csvDeltaPoints => 'variação (p.p.)';

  @override
  String get pdfVsPrevious => 'vs. anterior';

  @override
  String customRangeLimited(int days) {
    return 'Intervalo limitado a $days dias';
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
    return '$day: $count atendimentos, $series $value';
  }

  @override
  String get queueModeLabel => 'Modo da fila';

  @override
  String get modeQueue => 'Fila por chegada';

  @override
  String get modeSchedule => 'Hora marcada';

  @override
  String get slotsEditorTitle => 'Horários';

  @override
  String get slotsEditorHint => 'Fuso America/Sao_Paulo; repetem todo dia';

  @override
  String get slotTime => 'Horário';

  @override
  String slotCapacity(int count) {
    return 'Vagas: $count';
  }

  @override
  String get addSlot => 'Adicionar horário';

  @override
  String get removeSlot => 'Remover horário';

  @override
  String get slotsRequired => 'Adicione ao menos um horário';

  @override
  String get slotsDuplicate => 'Há horários repetidos';

  @override
  String slotsTooMany(int max) {
    return 'No máximo $max horários';
  }

  @override
  String get slotsInvalid => 'Horário ou vagas inválidos';

  @override
  String slotsOutsideSchedule(String time) {
    return 'Fora do horário de funcionamento: $time';
  }

  @override
  String slotsTileSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horários',
      one: '1 horário',
    );
    return '$_temp0';
  }

  @override
  String waitTileSlot(String time) {
    return 'Horário $time';
  }

  @override
  String get slotTimeChangeWarning =>
      'Quem já entrou neste horário continua na vaga antiga; as vagas ocupadas seguem contando.';

  @override
  String get editQueue => 'Editar fila';

  @override
  String get editQueueHint => 'Nome, descrição e tempo médio';

  @override
  String get queueUpdated => 'Fila atualizada';

  @override
  String get duplicateQueue => 'Duplicar fila';

  @override
  String get duplicateQueueHint =>
      'Copia limite, horário, cor, modo, grupo e alertas';

  @override
  String get duplicateQueueCopyWord => 'cópia';

  @override
  String get queueDuplicated => 'Fila duplicada';

  @override
  String get advancedOptions => 'Opções avançadas';

  @override
  String get queueNameTooLong => 'No máximo 60 caracteres';

  @override
  String get descriptionTooLong => 'No máximo 300 caracteres';

  @override
  String get avgServiceInvalid => 'Informe de 1 a 240 minutos';

  @override
  String get avgServiceAutoHint =>
      'O tempo manual só vale até existir a estimativa automática, calculada a partir dos atendimentos.';

  @override
  String get savingQueue => 'Salvando…';

  @override
  String get actionErrorOffline =>
      'Sem conexão. Verifique a internet e tente novamente.';

  @override
  String get actionErrorAccessEnded =>
      'Acesso encerrado ou sem permissão para esta ação.';

  @override
  String get actionErrorConflict => 'A fila mudou. Tente de novo.';

  @override
  String get undo => 'Desfazer';

  @override
  String finishedServedUndo(String name) {
    return '$name marcado como atendido';
  }

  @override
  String finishedNoShowUndo(String name) {
    return '$name marcado como não compareceu';
  }

  @override
  String get queueSettingsTitle => 'Configurações da fila';

  @override
  String get queueQrShortcut => 'QR code da fila';

  @override
  String get queueQrTitle => 'QR code';

  @override
  String get queueGoneNotice => 'Esta fila não existe mais';

  @override
  String get tourPanelSettingsTitle => 'QR code e configurações';

  @override
  String get tourPanelSettingsBody =>
      'Toque na engrenagem para ver o QR code e ajustar a fila.';

  @override
  String get tourHomeAccountTitle => 'Sua conta e convites';

  @override
  String get tourHomeAccountBody =>
      'Aqui ficam sua conta e a opção de entrar como operador com um código de convite.';

  @override
  String get quickQr => 'QR code';

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
    return 'Mostrar QR code da fila $name';
  }

  @override
  String get searchQueuesHint => 'Buscar fila pelo nome';

  @override
  String get sortQueues => 'Ordenar filas';

  @override
  String get sortByName => 'Nome';

  @override
  String get sortByRecent => 'Mais recentes';

  @override
  String get sortByWaiting => 'Mais espera';

  @override
  String get noQueuesMatch => 'Nenhuma fila encontrada';

  @override
  String get addPerson => 'Adicionar pessoa';

  @override
  String get addPersonTitle => 'Adicionar pessoa à fila';

  @override
  String get addPersonHint => 'Para quem está no balcão e não usa o QR code.';

  @override
  String get manualPhoneLabel => 'Telefone (opcional)';

  @override
  String get manualPhoneInvalid => 'Use o formato (00) 00000-0000';

  @override
  String get manualNameRequired => 'Informe um nome com até 60 caracteres';

  @override
  String get manualSlotLabel => 'Horário';

  @override
  String manualSlotOption(String time, int capacity) {
    return '$time ($capacity vagas)';
  }

  @override
  String get manualSlotRequiredField => 'Escolha um horário';

  @override
  String get manualAddConfirm => 'Adicionar';

  @override
  String manualAdded(String name, int ticket) {
    return '$name entrou na fila com a senha $ticket';
  }

  @override
  String get manualBadge => 'Balcão';

  @override
  String get manualAddQueueFull => 'A fila está lotada no momento.';

  @override
  String get manualAddSlotFull => 'Este horário está lotado.';

  @override
  String get manualAddSlotRequired => 'Escolha um horário válido.';

  @override
  String get manualAddSlotPassed => 'Este horário já passou.';

  @override
  String get manualAddNotOpen =>
      'A fila precisa estar aberta para adicionar pessoas.';

  @override
  String get manualAddInvalid => 'Confira o nome e o telefone informados.';

  @override
  String get manualAddRateLimited =>
      'Muitas adições em pouco tempo. Aguarde alguns minutos.';

  @override
  String get manualAddPhoneDuplicate => 'Este telefone já está na fila.';

  @override
  String callPhoneTooltip(String name) {
    return 'Ligar para $name';
  }

  @override
  String get callPhoneFailed => 'Não foi possível abrir o discador';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get termsOfUse => 'Termos de uso';

  @override
  String get posterSize => 'TAMANHO DO CARTAZ';

  @override
  String get posterSizeA4 => 'A4';

  @override
  String get posterSizeA5 => 'A5';

  @override
  String get posterSizeTable => 'Cartão de mesa (10×15 cm)';

  @override
  String get posterHeadlineLabel => 'Frase no cartaz (opcional)';

  @override
  String get posterHeadlineHint => 'Ex.: Peça seu lugar sem esperar em pé';

  @override
  String get posterHeadlineInvalid => 'Use até 60 caracteres.';

  @override
  String get sharePdf => 'Compartilhar PDF';

  @override
  String get sharePdfError => 'Não foi possível compartilhar o PDF.';

  @override
  String posterPreviewSemantics(String size) {
    return 'Prévia do cartaz em $size';
  }

  @override
  String get slugTitle => 'Link curto';

  @override
  String get slugNone => 'Não definido';

  @override
  String get slugRemove => 'Remover link curto';

  @override
  String get slugDialogLabel => 'Nome do link';

  @override
  String get slugDialogHint => 'minha-loja';

  @override
  String slugPreview(String url) {
    return 'Link: $url';
  }

  @override
  String get slugInvalid =>
      'Use de 3 a 40 letras minúsculas, números ou hífen, sem hífen no início ou no fim.';

  @override
  String get slugReservedError => 'Esse nome é reservado. Escolha outro.';

  @override
  String get slugTakenError => 'Esse link já está em uso. Escolha outro.';

  @override
  String get slugSaved => 'Link curto salvo';

  @override
  String get slugRemoved => 'Link curto removido';

  @override
  String get slugReleaseNotice =>
      'Trocar o link invalida os QRs impressos com o link antigo. O link antigo fica reservado por 30 dias para você.';

  @override
  String get posterNameLossy =>
      'Alguns caracteres do texto não existem na fonte do PDF e serão omitidos ou trocados.';

  @override
  String get posterNameFallback => 'Fila';

  @override
  String get exportCsvWithPhone => 'Exportar CSV com telefone';

  @override
  String get exportPdfWithPhone => 'Exportar PDF com telefone';

  @override
  String get exportPhoneTitle => 'Incluir telefone?';

  @override
  String get exportPhoneWarning =>
      'O telefone é dado pessoal (LGPD). Por padrão a exportação não o inclui. Inclua apenas se precisar e proteja o arquivo.';

  @override
  String get exportPhoneConfirm => 'Incluir telefone';

  @override
  String get anonymizePhoneTitle => 'Não guardar telefone no histórico';

  @override
  String get anonymizePhoneHint =>
      'Ao concluir um atendimento, o telefone não é salvo no histórico.';

  @override
  String get expiryTitle => 'Expirar entradas esquecidas';

  @override
  String get expiryHint =>
      'Remove da fila quem ficou aguardando sem atividade. Não afeta quem já foi chamado.';

  @override
  String expiryAfterHours(int hours) {
    return 'Expirar após $hours h';
  }

  @override
  String get expiryClearOnClose => 'Limpar a fila ao fechar por horário';

  @override
  String get expiryResetTicketDaily => 'Reiniciar a senha todo dia';

  @override
  String get expiryResetTicketDailyHint =>
      'Zera na primeira vez em que a fila ficar vazia a cada novo dia.';

  @override
  String get dataSubjectTitle => 'Dados de um cliente';

  @override
  String get dataSubjectSubtitle =>
      'Atenda pedidos de acesso, correção ou eliminação de dados feitos por um cliente (LGPD).';

  @override
  String get dataSubjectPhoneLabel => 'Telefone do cliente';

  @override
  String get dataSubjectSearch => 'Buscar';

  @override
  String get dataSubjectNone =>
      'Nenhum dado encontrado para este telefone nas suas filas.';

  @override
  String dataSubjectFound(int count) {
    return 'Encontrado em $count fila(s)';
  }

  @override
  String dataSubjectQueueCounts(int history, int feedback, int entries) {
    return '$history no histórico, $feedback avaliações, $entries na fila agora';
  }

  @override
  String dataSubjectPeriod(String from, String to) {
    return 'De $from a $to';
  }

  @override
  String get dataSubjectExport => 'Exportar dados (CSV)';

  @override
  String get dataSubjectExportTruncated =>
      'A exportação foi limitada aos primeiros 5000 registros.';

  @override
  String get dataSubjectAnonymize => 'Anonimizar';

  @override
  String get dataSubjectDelete => 'Excluir';

  @override
  String get dataSubjectConfirmTitleAnonymize =>
      'Anonimizar dados deste cliente?';

  @override
  String get dataSubjectConfirmTitleDelete => 'Excluir dados deste cliente?';

  @override
  String get dataSubjectConfirmBodyAnonymize =>
      'O nome vira \"Anônimo\", o telefone é removido do histórico e os comentários de avaliação são apagados. Se o cliente estiver em alguma fila agora, ele é removido. Não dá para desfazer.';

  @override
  String get dataSubjectConfirmBodyDelete =>
      'Apaga o histórico e as avaliações deste telefone e remove o cliente de qualquer fila ativa. Não dá para desfazer.';

  @override
  String get dataSubjectConfirmLabel =>
      'Digite o telefone de novo para confirmar';

  @override
  String get dataSubjectConfirmButton => 'Confirmar';

  @override
  String dataSubjectDone(int count) {
    return 'Concluído: $count registro(s) tratado(s).';
  }

  @override
  String get dataSubjectPartial =>
      'Alguns registros não foram tratados. Busque de novo e tente outra vez.';

  @override
  String get dataSubjectRateLimited =>
      'Muitas consultas seguidas. Aguarde um pouco e tente de novo.';

  @override
  String get dataSubjectAuditNote =>
      'Cada consulta fica registrada para auditoria, sem nome nem telefone.';

  @override
  String get dataSubjectReauthTitle => 'Confirme sua identidade';

  @override
  String get dataSubjectReauthHint =>
      'Você vai confirmar sua identidade com o Google.';

  @override
  String get dataSubjectReauthButton => 'Confirmar identidade';

  @override
  String cqStepOf(int current, int total) {
    return 'Passo $current de $total';
  }

  @override
  String get cqContinue => 'Continuar';

  @override
  String get cqSkip => 'Pular';

  @override
  String get cqQuickCreate => 'Criar agora';

  @override
  String get cqMoreDetails => 'Mais detalhes';

  @override
  String get cqNameTitle => 'Como se chama a fila?';

  @override
  String get cqNameHint =>
      'Só o nome já basta. Você ajusta o resto depois no painel.';

  @override
  String get cqModeTitle => 'Como as pessoas entram?';

  @override
  String get cqModeQueueHint => 'Quem chega entra no fim da fila.';

  @override
  String get cqModeScheduleHint =>
      'Cada pessoa escolhe um dos horários que você define.';

  @override
  String get cqSuggestionsTitle => 'Sugestões de horários';

  @override
  String get cqSuggestEvery30 =>
      'Adicionar horários a cada 30 min, das 9h às 17h';

  @override
  String get cqSuggestEveryHour =>
      'Adicionar horários a cada hora, das 9h às 17h';

  @override
  String get cqCapacityTitle => 'Tempo médio e limite de espera';

  @override
  String cqCapacityHint(int minutes) {
    return 'Usamos o tempo médio para estimar a espera. Se pular, valem $minutes min por atendimento e sem limite de pessoas.';
  }

  @override
  String get cqAppearanceTitle => 'Escolha uma cor';

  @override
  String get cqAppearanceHint =>
      'Ela aparece na página que o cliente vê. Opcional.';

  @override
  String get cqScheduleTitle => 'Quando a fila funciona?';

  @override
  String get cqScheduleHint =>
      'Por padrão a fila fica sempre aberta. Você pode pausar ou fechar quando quiser.';

  @override
  String get cqReviewTitle => 'Revise e crie';

  @override
  String get cqReviewHint => 'Toque em Editar para mudar qualquer item.';

  @override
  String get cqEdit => 'Editar';

  @override
  String get cqSummaryEntry => 'Entrada';

  @override
  String get cqSummaryCapacity => 'Tempo e limite';

  @override
  String get cqSummarySchedule => 'Funcionamento';

  @override
  String cqAverageTime(String time) {
    return 'Tempo médio: $time';
  }

  @override
  String cqWaitingLimit(String limit) {
    return 'Limite de espera: $limit';
  }

  @override
  String cqLimitPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pessoas',
      one: '1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get cqAlwaysOpen => 'Sempre aberta';

  @override
  String get cqNoExpiry => 'Não expirar';

  @override
  String get cqDefaultColor => 'Padrão';

  @override
  String get cqGroupChosen => 'Em um grupo';

  @override
  String get cqSummaryName => 'Nome';

  @override
  String get cqCreateTimeout =>
      'Sem resposta. A fila pode ter sido criada: confira sua lista antes de tentar de novo.';

  @override
  String get cqResumeTitle => 'Continuar de onde parou?';

  @override
  String get cqResumeBody =>
      'Você tem uma fila em andamento que não foi criada. Quer continuar de onde parou ou descartar?';

  @override
  String get cqResume => 'Continuar';

  @override
  String get cqDiscardDraft => 'Descartar';

  @override
  String get cqSaveDraft => 'Salvar rascunho';

  @override
  String get cqDraftDiscardBody =>
      'Você já preencheu campos. Salve como rascunho para continuar depois ou descarte o que digitou.';

  @override
  String get cqCreatedTitle => 'Fila criada';

  @override
  String get cqCreatedHint =>
      'Compartilhe o link ou mostre o QR para as pessoas entrarem.';

  @override
  String get cqOpenPanel => 'Abrir painel';

  @override
  String get cqPolishTitle => 'Deixe sua fila mais bonita e completa';

  @override
  String get cqShortcutLogo => 'Logo e cor';

  @override
  String get cqShortcutShortLink => 'Link curto';

  @override
  String get cqShortcutOperators => 'Operadores';

  @override
  String get cqShortcutAlerts => 'Alertas';

  @override
  String get cqLimitTitle => 'Limite de filas atingido';

  @override
  String get cqCheckingLimit => 'Verificando seu limite de filas';

  @override
  String get cqShareLink => 'Compartilhar link';

  @override
  String get cqAlertsTitle => 'Quer receber alertas desta fila?';

  @override
  String get cqAlertsHint =>
      'Opcional. Avisamos você quando a espera, o não comparecimento ou a fila parada passarem do limite que escolher.';

  @override
  String get cqAlertsPushNote =>
      'Os avisos chegam por notificação. Se a conta recebe esses avisos é uma opção da tela Alertas operacionais, nas configurações da fila.';

  @override
  String get cqSummaryAlerts => 'Alertas';

  @override
  String get metricsScopeUngrouped => 'Filas sem grupo';

  @override
  String get groupOverviewTitle => 'Por grupo';

  @override
  String get groupOverviewHint => 'Toque num grupo para ver só as filas dele.';

  @override
  String get groupOverviewOpenHint => 'Ver só este grupo';

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
  String get groupPartialData => 'dados parciais';

  @override
  String get cmpColQueue => 'Fila';

  @override
  String get cmpColGroup => 'Grupo';

  @override
  String get cmpColServed => 'Atend.';

  @override
  String get cmpColWait => 'Espera';

  @override
  String get cmpColNoShow => 'Não comp.';

  @override
  String get cmpColRating => 'Nota';

  @override
  String sortByHint(String column) {
    return 'Ordenar por $column';
  }

  @override
  String get sortAscending => 'ordem crescente';

  @override
  String get sortDescending => 'ordem decrescente';

  @override
  String get scopePickerTitle => 'Escolher escopo';

  @override
  String get scopeSearchHint => 'Buscar grupo ou fila';

  @override
  String get scopeNoResults => 'Nada encontrado';

  @override
  String get csvGroup => 'grupo';

  @override
  String get csvQueuesCount => 'filas';

  @override
  String get csvPartialData => 'dados parciais';

  @override
  String get csvYes => 'sim';

  @override
  String get csvNo => 'não';

  @override
  String get csvDeltaTotalPct => 'variação atendimentos (%)';

  @override
  String get csvDeltaWaitPct => 'variação espera média (%)';

  @override
  String get csvDeltaMedianPct => 'variação mediana (%)';

  @override
  String get csvDeltaP90Pct => 'variação P90 (%)';

  @override
  String get csvDeltaNoShowPoints => 'variação não comparecimento (p.p.)';

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
  String get groupSectionCollapsed => 'recolhido';

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
      zero: 'Sem filas',
    );
    return '$_temp0';
  }

  @override
  String groupDeleteConfirmCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas ficarão sem grupo.',
      one: '1 fila ficará sem grupo.',
    );
    return 'Excluir o grupo \"$name\"? $_temp0';
  }

  @override
  String groupBatchMenuLabel(String name) {
    return 'Ações em lote do grupo $name';
  }

  @override
  String get groupPauseAll => 'Pausar todas';

  @override
  String get groupCloseAll => 'Fechar todas';

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
    return 'Pausar $_temp0 do grupo \"$name\"?';
  }

  @override
  String groupBatchConfirmClose(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return 'Fechar $_temp0 do grupo \"$name\"?';
  }

  @override
  String groupBatchConfirmReopen(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas',
      one: '1 fila',
    );
    return 'Reabrir $_temp0 do grupo \"$name\"?';
  }

  @override
  String groupBatchDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas atualizadas',
      one: '1 fila atualizada',
    );
    return '$_temp0';
  }

  @override
  String groupBatchPartial(int done, int total) {
    return '$done de $total atualizadas. Tente de novo para as demais.';
  }

  @override
  String get groupBatchEmpty => 'Nenhuma fila do grupo para atualizar.';

  @override
  String groupReorderHandle(String name) {
    return 'Arrastar para reordenar o grupo \"$name\"';
  }

  @override
  String get groupMoveUp => 'Mover para cima';

  @override
  String get groupMoveDown => 'Mover para baixo';

  @override
  String groupMoved(String name, int position) {
    return 'Grupo \"$name\" na posição $position';
  }

  @override
  String get groupColor => 'Cor do grupo';

  @override
  String groupColorOf(String name) {
    return 'Cor do grupo \"$name\"';
  }

  @override
  String get groupColorNone => 'Sem cor';

  @override
  String get queueSelect => 'Selecionar filas';

  @override
  String get selectionExit => 'Sair da seleção';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filas selecionadas',
      one: '1 fila selecionada',
      zero: 'Nenhuma fila selecionada',
    );
    return '$_temp0';
  }

  @override
  String queueSelectLabel(String name) {
    return 'Selecionar a fila $name';
  }

  @override
  String get moveToGroup => 'Mover para grupo…';

  @override
  String moveToGroupTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mover $count filas para',
      one: 'Mover 1 fila para',
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
    return '$_temp0 para \"$group\"';
  }

  @override
  String moveGroupPartial(int done, int total) {
    return '$done de $total filas movidas. Tente de novo para as demais.';
  }

  @override
  String get moveGroupEmpty =>
      'Nenhuma das filas selecionadas pôde ser movida.';

  @override
  String get groupApplyAlerts => 'Aplicar alertas a todas as filas';

  @override
  String groupAlertsDialogTitle(String name) {
    return 'Alertas do grupo \"$name\"';
  }

  @override
  String get groupAlertsDialogHint =>
      'Esta configuração será copiada para todas as filas do grupo, no lugar da atual.';

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
    return 'Aplicar esta configuração de alertas a $_temp0 do grupo \"$name\"? Os alertas atuais dessas filas serão substituídos.';
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
  String get groupHistoryTitle => 'Histórico do grupo';

  @override
  String get groupHistoryOpen => 'Histórico do grupo';

  @override
  String get groupHistoryNoQueues => 'Nenhuma fila neste grupo';

  @override
  String get groupHistoryNoQueuesHint =>
      'Coloque filas no grupo para ver o histórico consolidado.';

  @override
  String groupHistoryTruncated(int limit, String queues) {
    return 'Mostrando só os $limit registros mais recentes de cada fila. Filas com histórico cortado: $queues.';
  }

  @override
  String groupHistoryShowMore(int shown, int total) {
    return 'Mostrar mais ($shown de $total)';
  }

  @override
  String historyQueueOrigin(String name) {
    return 'Fila: $name';
  }

  @override
  String get colQueue => 'Fila';

  @override
  String infoButtonSemantics(String name) {
    return 'Explicação do indicador: $name';
  }

  @override
  String get infoWhat => 'O que é';

  @override
  String get infoHow => 'Como é calculado';

  @override
  String get infoData => 'Dados usados';

  @override
  String get infoUse => 'Para que serve';

  @override
  String get infoClose => 'Fechar';

  @override
  String get attColService => 'Tempo médio';

  @override
  String get attColDeviation => 'Desvio';

  @override
  String get attColRate => 'Atend./h';

  @override
  String get attColIdle => 'Ocioso';

  @override
  String attInsufficientNote(int samples) {
    return '— indica amostra insuficiente (menos de $samples atendimentos ou janela curta).';
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
    return '$name. $served atendimentos, tempo médio $service, desvio $deviation, $rate atendimentos por hora, ociosidade $idle, $noShow não compareceram, nota $rating';
  }

  @override
  String get attChartTitleHour => 'Atendimentos por hora do dia';

  @override
  String get attChartTitleShift => 'Atendimentos por turno';

  @override
  String get attChartModeHour => 'Hora';

  @override
  String get attChartModeShift => 'Turno';

  @override
  String get attChartOperatorLabel => 'Atendente do gráfico';

  @override
  String get attChartAll => 'Todos os atendentes';

  @override
  String get attChartEmpty => 'Sem atendimentos concluídos para este gráfico.';

  @override
  String attChartPeak(String label, int count) {
    return 'Mais atendimentos: $label ($count)';
  }

  @override
  String attChartSemantics(String summary) {
    return 'Gráfico de atendimentos. $summary';
  }

  @override
  String get attShiftMorning => 'Manhã (6h–12h)';

  @override
  String get attShiftAfternoon => 'Tarde (12h–18h)';

  @override
  String get attShiftNight => 'Noite (18h–6h)';

  @override
  String get csvDeviationPct => 'desvio vs média (%)';

  @override
  String get csvRatePerHour => 'atendimentos por hora (janela de atuação)';

  @override
  String get csvIdlePct => 'ociosidade (%)';

  @override
  String get abandonTitle => 'Desistências';

  @override
  String get abandonSubtitle =>
      'Quem entrou e saiu antes de ser atendido. Remoções automáticas (expiração e fechamento) não contam.';

  @override
  String abandonBand(int start, int end) {
    return '$start–$end min';
  }

  @override
  String abandonBandOpen(int start) {
    return '$start+ min';
  }

  @override
  String get abandonWaitTitle => 'Taxa por faixa de espera';

  @override
  String get abandonWaitHint =>
      'Desistências a cada 10 min de espera, entre quem chegou a cada faixa.';

  @override
  String abandonWaitEmpty(int min) {
    return 'Amostra insuficiente: cada faixa precisa de pelo menos $min pessoas para mostrar a taxa.';
  }

  @override
  String abandonBarSpoken(String band, int pct) {
    return '$band: $pct% a cada 10 min';
  }

  @override
  String abandonBarNoData(String band) {
    return '$band: dados insuficientes';
  }

  @override
  String abandonInflectionFound(String band, int limit) {
    return 'Ponto de inflexão: a partir de $band a desistência passa de $limit% a cada 10 min.';
  }

  @override
  String abandonInflectionNone(int limit) {
    return 'Nenhuma faixa passa do limite de $limit% a cada 10 min.';
  }

  @override
  String get abandonEstimateTitle => 'Taxa por estimativa mostrada';

  @override
  String get abandonEstimateHint =>
      'Percentual de desistência conforme a estimativa que o cliente viu ao entrar.';

  @override
  String get abandonEstimateEmpty =>
      'Ainda não há registros com a estimativa mostrada na entrada. O histórico anterior à atualização que grava a estimativa não tem esse dado.';

  @override
  String abandonEstimateBarSpoken(String band, int pct) {
    return 'Estimativa $band: $pct% desistiram';
  }

  @override
  String abandonEstimateBarNoData(String band) {
    return 'Estimativa $band: dados insuficientes';
  }

  @override
  String get estimateAccuracyTitle => 'Precisão da estimativa';

  @override
  String estimateAccuracyMean(String value, int samples) {
    return 'Espera real menos estimativa: $value min em média ($samples atendimentos)';
  }

  @override
  String estimateAccuracyAbs(String value) {
    return 'Erro absoluto médio: $value min';
  }

  @override
  String get estimateAccuracyHint =>
      'Positivo: a espera foi maior que o prometido.';

  @override
  String estimateAccuracyNone(int min) {
    return 'Amostra insuficiente: são necessários $min atendimentos com estimativa gravada.';
  }

  @override
  String get abandonHourTitle => 'Desistência por hora de chegada';

  @override
  String get abandonHourRateLabel => 'Taxa';

  @override
  String get abandonHourCountLabel => 'Desistentes';

  @override
  String abandonHourEmpty(int min) {
    return 'Amostra insuficiente: cada hora precisa de pelo menos $min pessoas para mostrar a taxa.';
  }

  @override
  String abandonHourPeak(String hour, int pct, int left, int total) {
    return 'Maior taxa às $hour: $pct% ($left de $total)';
  }

  @override
  String abandonHourSpoken(String hour, int pct, int left, int total) {
    return '$hour: $pct% desistiram ($left de $total)';
  }

  @override
  String abandonHourNoRate(String hour, int left, int total) {
    return '$hour: $left de $total, taxa com dados insuficientes';
  }

  @override
  String get capacityCardTitle => 'Possível falta de capacidade';

  @override
  String capacityCardBody(String hours, int wait, int rate) {
    return 'Nestes horários a espera média é de $wait min ou mais e $rate% ou mais desistem: $hours. Considere reforçar o atendimento.';
  }

  @override
  String get capacityCardNone => 'Nenhum horário crítico no período';

  @override
  String get csvWaitBand => 'faixa de espera (min)';

  @override
  String get csvEstimateBand => 'faixa de estimativa (min)';

  @override
  String get csvAtRisk => 'chegaram à faixa';

  @override
  String get csvAbandonRatePct => 'desistência (%)';

  @override
  String get csvAbandonPer10Pct => 'desistência por 10 min (%)';

  @override
  String get csvInflection => 'ponto de inflexão';

  @override
  String get csvCapacityHours => 'horas com sinal de capacidade';

  @override
  String get csvEstimateErrorMin => 'erro médio da estimativa (min)';

  @override
  String get csvEstimateAbsErrorMin =>
      'erro absoluto médio da estimativa (min)';

  @override
  String get biNameAttendantThroughput => 'Atendimentos por hora e turno';

  @override
  String get biWhatAttendantThroughput =>
      'Quantos atendimentos cada atendente concluiu, distribuídos por hora do dia (0 a 23) e por turno (manhã 6h–12h, tarde 12h–18h, noite 18h–6h).';

  @override
  String get biHowAttendantThroughput =>
      'Conta os atendidos agrupados pelo instante em que terminaram (ou foram chamados, se faltar o término), convertido para o horário de São Paulo. Não compareceu e desistência não contam.';

  @override
  String get biDataAttendantThroughput =>
      'Resultado, horário de término, horário da chamada e quem chamou.';

  @override
  String get biUseAttendantThroughput =>
      'Ver em que horários e turnos cada pessoa concentra o trabalho e dimensionar a escala.';

  @override
  String get biNameAttendantService => 'Tempo médio de serviço';

  @override
  String get biWhatAttendantService =>
      'Quanto tempo, em média, o atendente leva entre chamar o cliente e finalizar o atendimento.';

  @override
  String biHowAttendantService(int min) {
    return 'Média de (término − chamada) dos atendidos. Com menos de $min amostras válidas o valor não é mostrado (—).';
  }

  @override
  String get biDataAttendantService =>
      'Horário da chamada, horário de término e resultado “atendido”.';

  @override
  String get biUseAttendantService =>
      'Conhecer o ritmo real de cada pessoa e ajustar o tempo médio configurado na fila.';

  @override
  String get biNameAttendantDeviation => 'Desvio contra a média';

  @override
  String get biWhatAttendantDeviation =>
      'Quanto o tempo médio do atendente se afasta da média de todos no escopo selecionado. Negativo significa mais rápido.';

  @override
  String biHowAttendantDeviation(int min) {
    return '(média do atendente − média do escopo) ÷ média do escopo × 100. A média do escopo é ponderada pelas amostras. Só entram atendentes com pelo menos $min amostras; os demais mostram —.';
  }

  @override
  String get biDataAttendantDeviation =>
      'Tempo de serviço dos atendidos de cada atendente.';

  @override
  String get biUseAttendantDeviation =>
      'Identificar quem destoa do padrão, para treino ou revisão do tempo médio. Não mede qualidade: um atendimento mais longo pode ser mais complexo.';

  @override
  String get biNameAttendantRate =>
      'Atendimentos por hora na janela de atuação';

  @override
  String get biWhatAttendantRate =>
      'O ritmo do atendente dentro da janela em que atuou no dia. Pausas e intervalos entre atendimentos entram na janela; não é hora efetivamente trabalhada.';

  @override
  String biHowAttendantRate(int min, int window) {
    return 'Por dia: atendidos ÷ horas entre a primeira chamada e o último término. O dia só vale com $min ou mais atendimentos e janela de pelo menos $window min. O valor mostrado soma atendimentos e horas dos dias válidos.';
  }

  @override
  String get biDataAttendantRate =>
      'Horário da chamada, horário de término, resultado e quem chamou.';

  @override
  String get biUseAttendantRate =>
      'Comparar produtividade sem o viés de quem trabalhou poucas horas.';

  @override
  String get biNameAttendantIdle => 'Ociosidade';

  @override
  String get biWhatAttendantIdle =>
      'Parcela do tempo em que o atendente ficou parado havendo gente esperando.';

  @override
  String biHowAttendantIdle(int cap, int min) {
    return 'Soma dos intervalos entre o fim de um atendimento e a chamada do próximo, ÷ tempo observado no dia. O intervalo só conta se o próximo cliente já estava na fila, se for maior que zero e menor ou igual a $cap min (acima disso presume-se pausa) e se ocorrer no mesmo dia. Só aparece com pelo menos $min atendimentos concluídos.';
  }

  @override
  String get biDataAttendantIdle =>
      'Horário de entrada na fila, da chamada e do término. É uma aproximação: o histórico não guarda o tamanho da fila em cada instante.';

  @override
  String get biUseAttendantIdle =>
      'Achar tempo perdido entre atendimentos (troca lenta, distração) separando-o de fila vazia.';

  @override
  String get biNameAbandonWait => 'Desistência por faixa de espera';

  @override
  String get biWhatAbandonWait =>
      'De quem esperou pelo menos até certo ponto, a fração que desistiu naquela faixa.';

  @override
  String biHowAbandonWait(String bands, int min) {
    return 'Faixas de $bands min. Em cada faixa: pessoas que desistiram na faixa ÷ pessoas que chegaram a ela (inclusive quem esperou mais e foi atendido). As barras mostram a taxa a cada 10 min (limitada a 100%; faixas mais estreitas que 5 min usam 5 min no divisor), para comparar faixas de larguras diferentes. Faixa com menos de $min pessoas não mostra taxa.';
  }

  @override
  String get biDataAbandonWait =>
      'Resultado, horário de entrada, chamada e término, e motivo de saída. Remoções do sistema (expirada ou fechada) ficam de fora. Quem ainda está na fila não aparece, então esperas longas recentes podem estar sub-representadas.';

  @override
  String get biUseAbandonWait =>
      'Mostrar a partir de que espera o cliente começa a ir embora.';

  @override
  String get biNameAbandonInflection => 'Ponto de inflexão';

  @override
  String get biWhatAbandonInflection =>
      'A primeira faixa de espera em que a desistência passa do tolerável.';

  @override
  String biHowAbandonInflection(int limit) {
    return 'Primeira faixa, em ordem crescente, com mais de $limit% de desistência a cada 10 minutos. Faixas sem taxa (amostra insuficiente) são puladas. Se nenhuma passar, não há ponto de inflexão.';
  }

  @override
  String get biDataAbandonInflection => 'A mesma taxa por faixa de espera.';

  @override
  String get biUseAbandonInflection =>
      'Definir a meta de espera máxima e o texto de aviso ao cliente.';

  @override
  String get biNameAbandonEstimate => 'Desistência por estimativa mostrada';

  @override
  String get biWhatAbandonEstimate =>
      'A taxa de desistência separada pela estimativa de espera que o cliente viu ao entrar na fila.';

  @override
  String biHowAbandonEstimate(String bands, int min) {
    return 'Agrupa por estimativa ($bands min): desistentes ÷ total de pessoas que viram aquela estimativa. Faixa com menos de $min pessoas não mostra taxa.';
  }

  @override
  String get biDataAbandonEstimate =>
      'Estimativa gravada na entrada e resultado. Registros anteriores à atualização que grava a estimativa não têm o campo e ficam de fora.';

  @override
  String get biUseAbandonEstimate =>
      'Saber se prometer uma espera longa afasta clientes, e se vale mostrar a estimativa de outra forma.';

  @override
  String get biNameEstimateAccuracy => 'Precisão da estimativa';

  @override
  String get biWhatEstimateAccuracy =>
      'O quanto a estimativa mostrada ao cliente errou, em minutos.';

  @override
  String biHowEstimateAccuracy(int min) {
    return 'Média de (espera real − estimativa) para atendidos e não compareceu. Positivo: a espera foi maior que o prometido. Também mostra o erro absoluto médio, que não deixa erros positivos e negativos se anularem. Menos de $min amostras: não calcula.';
  }

  @override
  String get biDataEstimateAccuracy =>
      'Estimativa gravada na entrada, horário de entrada e de chamada. Registros anteriores à gravação da estimativa ficam de fora.';

  @override
  String get biUseEstimateAccuracy =>
      'Avaliar se o tempo médio configurado reflete a realidade e quando ajustá-lo.';

  @override
  String get biNameAbandonHour => 'Desistência por hora de chegada';

  @override
  String get biWhatAbandonHour =>
      'A taxa e a quantidade de desistências conforme a hora em que a pessoa entrou na fila.';

  @override
  String biHowAbandonHour(int min) {
    return 'Agrupa pela hora de entrada (São Paulo). Taxa = desistentes ÷ (atendidos + não compareceu + desistentes). Hora com menos de $min pessoas não mostra taxa, mas a contagem aparece.';
  }

  @override
  String get biDataAbandonHour =>
      'Resultado, horário de entrada, espera e motivo de saída. Remoções do sistema ficam de fora.';

  @override
  String get biUseAbandonHour => 'Localizar os horários de pico problemáticos.';

  @override
  String get biNameCapacitySignal => 'Sinal de capacidade';

  @override
  String get biWhatCapacitySignal =>
      'As horas em que a fila parece subdimensionada.';

  @override
  String biHowCapacitySignal(int wait, int rate) {
    return 'Horas com espera média de $wait min ou mais e taxa de desistência de $rate% ou mais. Horas sem taxa (amostra insuficiente) não entram.';
  }

  @override
  String get biDataCapacitySignal =>
      'A desistência por hora de chegada e a espera média de cada hora.';

  @override
  String get biUseCapacitySignal =>
      'Indicar onde reforçar atendentes ou ajustar horários.';

  @override
  String abandonBarCounts(int left, int total) {
    return '$left de $total desistiram';
  }

  @override
  String abandonScopeQueue(String name) {
    return 'Fila: $name (filtro da seção Por atendente)';
  }

  @override
  String get goalsTitle => 'Metas de atendimento';

  @override
  String get goalsNone => 'Sem metas definidas';

  @override
  String goalsValueWait(int min) {
    return 'Espera até $min min';
  }

  @override
  String goalsValueService(int min) {
    return 'Atendimento até $min min';
  }

  @override
  String goalsValueTarget(int pct) {
    return 'alvo $pct%';
  }

  @override
  String get goalsDialogHint =>
      'Defina o tempo aceitável e a parte dos atendimentos que deve cumprir a meta. Deixe em branco o que não quiser medir.';

  @override
  String get goalsWaitLabel => 'Espera máxima (min)';

  @override
  String get goalsServiceLabel => 'Atendimento máximo (min)';

  @override
  String get goalsTargetLabel => 'Alvo de cumprimento (%)';

  @override
  String goalsTargetHint(int pct) {
    return 'Padrão $pct';
  }

  @override
  String goalsErrRange(int min, int max) {
    return 'Informe de $min a $max minutos.';
  }

  @override
  String goalsErrTarget(int min, int max) {
    return 'Informe de $min a $max%.';
  }

  @override
  String get goalsErrNone =>
      'Defina pelo menos uma meta: espera ou atendimento.';

  @override
  String get goalsRemove => 'Remover metas';

  @override
  String get goalRiskTitle => 'Meta de espera em risco';

  @override
  String goalRiskBody(int waiting, int est, int goal) {
    return 'Com $waiting na fila, a espera estimada é de $est min, acima da meta de $goal min.';
  }

  @override
  String get goalRiskAction =>
      'Sugestão: chame mais um atendente ou abra outro balcão.';

  @override
  String get goalsSectionTitle => 'Metas';

  @override
  String get goalsSectionSubtitle =>
      'Cumprimento das metas definidas em cada fila, no período e escopo escolhidos.';

  @override
  String goalsQueuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Metas de $count filas no escopo',
      one: 'Meta de 1 fila no escopo',
    );
    return '$_temp0';
  }

  @override
  String get goalsWaitCardTitle => 'Espera dentro da meta';

  @override
  String get goalsServiceCardTitle => 'Atendimento dentro da meta';

  @override
  String goalsTargetLine(int pct) {
    return 'Alvo: $pct% dentro do limite';
  }

  @override
  String goalsCounts(int ok, int total) {
    return '$ok de $total dentro do limite';
  }

  @override
  String get goalsMet => 'Atingida';

  @override
  String get goalsNotMet => 'Não atingida';

  @override
  String goalsSmallSample(int min) {
    return 'Amostra pequena: menos de $min atendimentos avaliados.';
  }

  @override
  String get goalsNoSamples =>
      'Sem atendimentos no período para avaliar esta meta.';

  @override
  String get goalsNotSet => 'Nenhuma fila do escopo tem esta meta.';

  @override
  String get goalsDailyTitle => 'Cumprimento por dia';

  @override
  String goalsDailySemantics(int days, int missed) {
    return '$days dias avaliados, $missed abaixo do alvo';
  }

  @override
  String get goalsMissedTitle => 'Períodos em que a meta não foi atingida';

  @override
  String goalsMissedNone(int min) {
    return 'Nenhum dia ou hora abaixo do alvo com pelo menos $min avaliados.';
  }

  @override
  String get goalsKindWait => 'Espera';

  @override
  String get goalsKindService => 'Atendimento';

  @override
  String goalsMissedDayRow(
    String kind,
    String day,
    int pct,
    int ok,
    int total,
    int target,
  ) {
    return '$kind, $day: $pct% ($ok de $total), alvo $target%';
  }

  @override
  String goalsMissedHoursRow(String kind, String hours) {
    return '$kind, horas abaixo do alvo: $hours';
  }

  @override
  String goalsMissedMore(int count) {
    return 'e mais $count dias';
  }

  @override
  String goalsWorstWait(int over, String day) {
    return 'Maior violação de espera: $over min acima da meta, em $day.';
  }

  @override
  String goalsWorstService(int over, String day) {
    return 'Maior violação de atendimento: $over min acima da meta, em $day.';
  }

  @override
  String get goalsNoViolation => 'Nenhuma violação no período.';

  @override
  String get goalsCtaTitle => 'Defina metas de atendimento';

  @override
  String get goalsCtaBody =>
      'Nenhuma fila deste escopo tem metas. Abra a fila, vá em Configurações e use Metas de atendimento para acompanhar o cumprimento aqui.';

  @override
  String get staffTitle => 'Planejamento de equipe';

  @override
  String get staffSubtitle =>
      'Quantos atendentes cada dia e hora exigem, comparado com quem realmente atendeu.';

  @override
  String staffServiceTime(String min, int samples) {
    return 'Tempo médio de atendimento: $min min ($samples atendimentos)';
  }

  @override
  String staffServiceNone(int min) {
    return 'Tempo médio indisponível: são necessários pelo menos $min atendimentos concluídos.';
  }

  @override
  String staffOccupancy(int pct) {
    return 'Ocupação-alvo: $pct%';
  }

  @override
  String staffCoverage(int days) {
    return 'Base: $days dias com dados';
  }

  @override
  String get staffModeRequired => 'Recomendado';

  @override
  String get staffModeObserved => 'Observado';

  @override
  String get staffModeGap => 'Diferença';

  @override
  String get staffGridTitle => 'Atendentes por dia e hora';

  @override
  String staffHintRequired(int pct) {
    return 'Atendentes recomendados para absorver a demanda média, com ocupação-alvo de $pct%.';
  }

  @override
  String get staffHintObserved =>
      'Média de atendentes distintos que atenderam em cada dia e hora.';

  @override
  String get staffHintGap =>
      'Recomendado menos observado. Positivo: falta gente. Negativo: folga.';

  @override
  String get staffLegendDeficit => 'Falta';

  @override
  String get staffLegendOk => 'Equilibrado';

  @override
  String get staffLegendSurplus => 'Folga';

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
    return 'Grade de atendentes por dia da semana e hora, modo $mode. $top';
  }

  @override
  String get staffTopTitle => 'Maiores déficits';

  @override
  String staffTopRow(String day, String hour, int required, String observed) {
    return '$day $hour: precisa de $required, tem $observed';
  }

  @override
  String get staffTopNone =>
      'Nenhum déficit: a equipe observada cobre a demanda recomendada.';

  @override
  String get staffNoData =>
      'Sem chegadas no período para dimensionar a equipe.';

  @override
  String get staffSeasonTitle => 'Volume semanal e sazonalidade';

  @override
  String staffSeasonInsufficient(int need, int have) {
    return 'Dados insuficientes: são necessárias pelo menos $need semanas completas com dados (há $have).';
  }

  @override
  String staffTrendUp(String pct) {
    return 'Tendência de alta: cerca de +$pct% por semana.';
  }

  @override
  String staffTrendDown(String pct) {
    return 'Tendência de queda: cerca de $pct% por semana.';
  }

  @override
  String staffTrendStable(int pct) {
    return 'Volume estável: variação abaixo de $pct% por semana.';
  }

  @override
  String staffWeekSpoken(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chegadas',
      one: '1 chegada',
    );
    return 'Semana de $date: $_temp0';
  }

  @override
  String get staffRecurringTitle => 'Padrão recorrente';

  @override
  String staffRecurringRow(String day, String hour, int weeks, int total) {
    return '$day $hour: entre as mais cheias em $weeks de $total semanas';
  }

  @override
  String staffRecurringNone(int pct) {
    return 'Nenhuma hora se repete entre as mais cheias em pelo menos $pct% das semanas.';
  }

  @override
  String get csvGoalIndicator => 'indicador';

  @override
  String get csvEvaluated => 'avaliados';

  @override
  String get csvWithinLimit => 'dentro do limite';

  @override
  String get csvPctWithinLimit => '% dentro do limite';

  @override
  String get csvTargetPct => 'alvo %';

  @override
  String get csvGoalMet => 'meta atingida';

  @override
  String get csvWorstOverMin => 'maior violação (min)';

  @override
  String get csvWorstDay => 'dia da maior violação';

  @override
  String get csvMissedDays => 'dias abaixo do alvo';

  @override
  String get csvMissedHours => 'horas abaixo do alvo';

  @override
  String get csvArrivalsPerHour => 'chegadas por hora';

  @override
  String get csvRequiredStaff => 'atendentes recomendados';

  @override
  String get csvObservedStaff => 'atendentes observados';

  @override
  String get csvGapStaff => 'diferença';

  @override
  String get csvWeekStart => 'início da semana';

  @override
  String get csvTrendPct => 'tendência (% da média por semana)';

  @override
  String get csvRecurringWeeks => 'semanas entre as mais cheias';

  @override
  String get csvOccupancyPct => 'ocupação-alvo %';

  @override
  String get csvCoverageDays => 'dias com dados';

  @override
  String get biNameGoalWait => 'Espera dentro da meta';

  @override
  String get biWhatGoalWait =>
      'A parte dos atendimentos em que a pessoa esperou até o limite de espera definido na fila.';

  @override
  String biHowGoalWait(int min) {
    return 'Compara a espera (chamada menos entrada) de cada atendido e não compareceu com a meta de espera. Quem desistiu só entra se esperou mais que a meta, e conta como descumprimento; desistência abaixo da meta e remoções do sistema ficam de fora. Percentual = dentro do limite ÷ avaliados. A meta é atingida quando o percentual alcança o alvo (padrão 80%). Com várias filas, cada pessoa é comparada à meta da própria fila e o alvo mostrado é a média ponderada pelos avaliados. Abaixo de $min avaliados, o resultado é marcado como amostra pequena.';
  }

  @override
  String get biDataGoalWait =>
      'Resultado, horário de entrada, de chamada e de saída (desistência) e as metas da fila. Sem telefone.';

  @override
  String get biUseGoalWait =>
      'Saber se o serviço está dentro do prazo prometido e quando ele falha.';

  @override
  String get biNameGoalService => 'Atendimento dentro da meta';

  @override
  String get biWhatGoalService =>
      'A parte dos atendimentos concluídos que durou até o tempo máximo definido na fila.';

  @override
  String biHowGoalService(int min) {
    return 'Só atendimentos concluídos (atendidos). Compara a duração (fim menos chamada) com a meta de atendimento. Percentual = dentro do limite ÷ avaliados; a meta é atingida quando alcança o alvo. Não comparecimentos e desistências não entram. Abaixo de $min avaliados, o resultado é marcado como amostra pequena.';
  }

  @override
  String get biDataGoalService =>
      'Resultado, horário de chamada e de término e as metas da fila.';

  @override
  String get biUseGoalService =>
      'Verificar se os atendimentos cabem no tempo esperado e achar dias e horas lentos.';

  @override
  String get biNameGoalMissed => 'Períodos em que a meta não foi atingida';

  @override
  String get biWhatGoalMissed =>
      'Dias e horas do dia em que o cumprimento ficou abaixo do alvo, e a maior violação.';

  @override
  String biHowGoalMissed(int min) {
    return 'Agrupa os avaliados por dia e por hora do dia (São Paulo). Lista os dias e as horas com pelo menos $min avaliados e percentual abaixo do alvo. A maior violação é o maior excesso, em minutos, sobre o limite de espera ou de atendimento. Dias e horas com menos avaliados não são listados.';
  }

  @override
  String get biDataGoalMissed =>
      'Os mesmos dos indicadores de espera e de atendimento dentro da meta.';

  @override
  String get biUseGoalMissed =>
      'Achar quando a meta falha de forma recorrente e reforçar a equipe nesses períodos.';

  @override
  String get biNameStaffingService => 'Tempo médio de atendimento';

  @override
  String get biWhatStaffingService =>
      'A duração média dos atendimentos concluídos, usada para estimar quantos atendentes são necessários.';

  @override
  String biHowStaffingService(int min) {
    return 'Média de fim menos chamada dos atendimentos concluídos (atendidos) do escopo e período. Com menos de $min atendimentos não é calculada e a recomendação de atendentes fica indisponível.';
  }

  @override
  String get biDataStaffingService =>
      'Resultado, horário de chamada e de término.';

  @override
  String get biUseStaffingService =>
      'Servir de base para o cálculo de atendentes recomendados.';

  @override
  String get biNameStaffingRequired => 'Atendentes recomendados';

  @override
  String get biWhatStaffingRequired =>
      'Quantos atendentes cada dia da semana e hora exigem para absorver a demanda média.';

  @override
  String biHowStaffingRequired(int pct) {
    return 'Chegadas por hora = chegadas naquele dia da semana e hora ÷ número de vezes que esse dia da semana ocorre entre o primeiro e o último dia com dados (inclui quem desistiu e não compareceu). Recomendados = arredondar para cima (chegadas por hora × tempo médio de atendimento em horas ÷ ocupação-alvo de $pct%). Indisponível sem tempo médio de atendimento.';
  }

  @override
  String get biDataStaffingRequired =>
      'Hora de entrada de todas as pessoas, resultado, horário de chamada e de término.';

  @override
  String get biUseStaffingRequired =>
      'Montar escalas: ver em que dias e horas a equipe precisa ser maior.';

  @override
  String get biNameStaffingObserved => 'Atendentes observados';

  @override
  String get biWhatStaffingObserved =>
      'Quantos atendentes distintos realmente atenderam em cada dia da semana e hora.';

  @override
  String get biHowStaffingObserved =>
      'Para cada data e hora, conta os atendentes distintos com atendimento em andamento, da chamada ao fim (atendimentos longos contam em todas as horas que atravessam). Soma por dia da semana e hora e divide pelo mesmo número de ocorrências do dia da semana usado nas chegadas. O dono e registros sem atendente contam como um atendente.';

  @override
  String get biDataStaffingObserved =>
      'Atendente, horário de chamada e de término, resultado (atendido ou não compareceu).';

  @override
  String get biUseStaffingObserved =>
      'Comparar a equipe que de fato atuou com a recomendada.';

  @override
  String get biNameStaffingGap => 'Déficit e folga';

  @override
  String get biWhatStaffingGap =>
      'A diferença entre atendentes recomendados e observados em cada dia e hora.';

  @override
  String biHowStaffingGap(int n) {
    return 'Diferença = recomendados menos observados. Positivo é déficit (falta gente); negativo é folga. A lista mostra as $n maiores diferenças positivas, desempatando por recomendados, dia e hora.';
  }

  @override
  String get biDataStaffingGap =>
      'Os mesmos dos atendentes recomendados e observados.';

  @override
  String get biUseStaffingGap =>
      'Priorizar onde reforçar a equipe e onde sobra capacidade.';

  @override
  String get biNameSeasonVolume => 'Volume semanal e tendência';

  @override
  String get biWhatSeasonVolume =>
      'Quantas pessoas entraram na fila em cada uma das últimas semanas e para onde o volume caminha.';

  @override
  String biHowSeasonVolume(int weeks, int band, int min) {
    return 'Conta as chegadas (inclui desistências e não comparecimentos) por semana, de segunda a domingo (São Paulo), nas últimas $weeks semanas completas, a partir da primeira semana com dados; a semana em andamento fica de fora. A tendência é a inclinação de uma reta ajustada aos volumes semanais, em % da média semanal por semana; abaixo de $band% é considerada estável. Com menos de $min semanas, mostra dados insuficientes.';
  }

  @override
  String get biDataSeasonVolume =>
      'Hora de entrada de todas as pessoas. Usa todo o histórico carregado do escopo, não só o período escolhido.';

  @override
  String get biUseSeasonVolume =>
      'Planejar equipe e espaço para os próximos períodos.';

  @override
  String get biNameSeasonPattern => 'Padrão recorrente';

  @override
  String get biWhatSeasonPattern =>
      'Dias da semana e horas que se repetem entre os mais movimentados, semana após semana.';

  @override
  String biHowSeasonPattern(int top, int pct, int min) {
    return 'Em cada semana observada, pega as $top células (dia da semana × hora) com mais chegadas. Uma célula é recorrente quando aparece nesse grupo em pelo menos $pct% das semanas observadas. Exige ao menos $min semanas.';
  }

  @override
  String get biDataSeasonPattern => 'Hora de entrada de todas as pessoas.';

  @override
  String get biUseSeasonPattern =>
      'Saber quais horários são movimentados sempre, e não por acaso.';
}
