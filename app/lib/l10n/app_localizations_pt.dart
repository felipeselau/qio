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
  String get backWithArrow => '← Voltar';

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
      'Toque no cartão para ver o QR code e chamar as pessoas.';

  @override
  String get tourHomeOperatorTitle => 'Entrar como operador';

  @override
  String get tourHomeOperatorBody =>
      'Recebeu um código de convite? Use aqui para ajudar em uma fila.';

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
    return '$count horários';
  }

  @override
  String waitTileSlot(String time) {
    return 'Horário $time';
  }

  @override
  String get slotTimeChangeWarning =>
      'Quem já entrou neste horário continua na vaga antiga; as vagas ocupadas seguem contando.';
}
