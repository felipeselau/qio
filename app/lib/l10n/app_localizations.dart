import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @backWithArrow.
  ///
  /// In pt, this message translates to:
  /// **'← Voltar'**
  String get backWithArrow;

  /// No description provided for @create.
  ///
  /// In pt, this message translates to:
  /// **'Criar'**
  String get create;

  /// No description provided for @remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get remove;

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @copy.
  ///
  /// In pt, this message translates to:
  /// **'Copiar'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get share;

  /// No description provided for @print.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir'**
  String get print;

  /// No description provided for @genericActionError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir a ação. Tente novamente.'**
  String get genericActionError;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In pt, this message translates to:
  /// **'E-mail ou senha incorretos.'**
  String get authInvalidCredentials;

  /// No description provided for @authInvalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'E-mail inválido.'**
  String get authInvalidEmail;

  /// No description provided for @authEmailInUse.
  ///
  /// In pt, this message translates to:
  /// **'Já existe uma conta com este e-mail.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha fraca. Use pelo menos 6 caracteres.'**
  String get authWeakPassword;

  /// No description provided for @authUserDisabled.
  ///
  /// In pt, this message translates to:
  /// **'Esta conta foi desativada.'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In pt, this message translates to:
  /// **'Muitas tentativas. Aguarde alguns minutos e tente de novo.'**
  String get authTooManyRequests;

  /// No description provided for @authNetworkError.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Verifique a internet e tente de novo.'**
  String get authNetworkError;

  /// No description provided for @authGeneric.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível entrar. Tente novamente.'**
  String get authGeneric;

  /// No description provided for @loginTagline.
  ///
  /// In pt, this message translates to:
  /// **'Sistema de filas inteligente'**
  String get loginTagline;

  /// No description provided for @nameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In pt, this message translates to:
  /// **'Seu nome'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu nome'**
  String get nameRequired;

  /// No description provided for @emailLabel.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In pt, this message translates to:
  /// **'voce@email.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o email'**
  String get emailRequired;

  /// No description provided for @passwordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordLabel;

  /// No description provided for @passwordMin.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get passwordMin;

  /// No description provided for @signIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccount;

  /// No description provided for @orSeparator.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get orSeparator;

  /// No description provided for @continueWithGoogle.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Google'**
  String get continueWithGoogle;

  /// No description provided for @haveAccountSignIn.
  ///
  /// In pt, this message translates to:
  /// **'Já tem conta? Entrar'**
  String get haveAccountSignIn;

  /// No description provided for @accountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Minha conta'**
  String get accountTitle;

  /// No description provided for @businessLine.
  ///
  /// In pt, this message translates to:
  /// **'Negócio: {business}'**
  String businessLine(String business);

  /// No description provided for @queuesCreated.
  ///
  /// In pt, this message translates to:
  /// **'Filas criadas'**
  String get queuesCreated;

  /// No description provided for @memberSince.
  ///
  /// In pt, this message translates to:
  /// **'Membro desde'**
  String get memberSince;

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair da conta'**
  String get signOut;

  /// No description provided for @signOutError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível sair da conta.'**
  String get signOutError;

  /// No description provided for @appearance.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearance;

  /// No description provided for @systemOption.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get systemOption;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @languageTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageTitle;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In pt, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @newQueue.
  ///
  /// In pt, this message translates to:
  /// **'Nova fila'**
  String get newQueue;

  /// No description provided for @queueNameLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome da fila *'**
  String get queueNameLabel;

  /// No description provided for @queueNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: Atendimento balcão'**
  String get queueNameHint;

  /// No description provided for @queueNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome'**
  String get queueNameRequired;

  /// No description provided for @descriptionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Descrição (opcional)'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In pt, this message translates to:
  /// **'Descreva o propósito da fila...'**
  String get descriptionHint;

  /// No description provided for @avgServiceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio de atendimento (minutos)'**
  String get avgServiceLabel;

  /// No description provided for @invalidNumber.
  ///
  /// In pt, this message translates to:
  /// **'Informe um número válido'**
  String get invalidNumber;

  /// No description provided for @createQueue.
  ///
  /// In pt, this message translates to:
  /// **'Criar fila'**
  String get createQueue;

  /// No description provided for @myQueues.
  ///
  /// In pt, this message translates to:
  /// **'Minhas filas'**
  String get myQueues;

  /// No description provided for @joinAsOperator.
  ///
  /// In pt, this message translates to:
  /// **'Entrar como operador'**
  String get joinAsOperator;

  /// No description provided for @tourHomeFabTitle.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua primeira fila'**
  String get tourHomeFabTitle;

  /// No description provided for @tourHomeFabBody.
  ///
  /// In pt, this message translates to:
  /// **'Toque no + para criar uma fila e gerar o QR code.'**
  String get tourHomeFabBody;

  /// No description provided for @tourHomeQueueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Abra sua fila'**
  String get tourHomeQueueTitle;

  /// No description provided for @tourHomeQueueBody.
  ///
  /// In pt, this message translates to:
  /// **'Toque no cartão para ver o QR code e chamar as pessoas.'**
  String get tourHomeQueueBody;

  /// No description provided for @tourHomeOperatorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Entrar como operador'**
  String get tourHomeOperatorTitle;

  /// No description provided for @tourHomeOperatorBody.
  ///
  /// In pt, this message translates to:
  /// **'Recebeu um código de convite? Use aqui para ajudar em uma fila.'**
  String get tourHomeOperatorBody;

  /// No description provided for @emptyQueuesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila ainda'**
  String get emptyQueuesTitle;

  /// No description provided for @emptyQueuesBody.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua primeira fila ou entre como operador com um código de convite'**
  String get emptyQueuesBody;

  /// No description provided for @sectionOwner.
  ///
  /// In pt, this message translates to:
  /// **'SOU DONO'**
  String get sectionOwner;

  /// No description provided for @sectionOperator.
  ///
  /// In pt, this message translates to:
  /// **'SOU OPERADOR'**
  String get sectionOperator;

  /// No description provided for @sectionRequests.
  ///
  /// In pt, this message translates to:
  /// **'PEDIDOS DE OPERADOR'**
  String get sectionRequests;

  /// No description provided for @waitingCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} pessoa esperando} other{{count} pessoas esperando}}'**
  String waitingCount(int count);

  /// No description provided for @createdOn.
  ///
  /// In pt, this message translates to:
  /// **'Criada em {date}'**
  String createdOn(DateTime date);

  /// No description provided for @youAreOperator.
  ///
  /// In pt, this message translates to:
  /// **'Você é operador desta fila'**
  String get youAreOperator;

  /// No description provided for @requestRemovedStatus.
  ///
  /// In pt, this message translates to:
  /// **'Você foi removido desta fila'**
  String get requestRemovedStatus;

  /// No description provided for @requestRejectedStatus.
  ///
  /// In pt, this message translates to:
  /// **'Pedido recusado'**
  String get requestRejectedStatus;

  /// No description provided for @awaitingApproval.
  ///
  /// In pt, this message translates to:
  /// **'Aguardando aprovação'**
  String get awaitingApproval;

  /// No description provided for @dismiss.
  ///
  /// In pt, this message translates to:
  /// **'Dispensar'**
  String get dismiss;

  /// No description provided for @statusOpen.
  ///
  /// In pt, this message translates to:
  /// **'Aberta'**
  String get statusOpen;

  /// No description provided for @statusPaused.
  ///
  /// In pt, this message translates to:
  /// **'Pausada'**
  String get statusPaused;

  /// No description provided for @statusClosed.
  ///
  /// In pt, this message translates to:
  /// **'Fechada'**
  String get statusClosed;

  /// No description provided for @joinOperatorIntro.
  ///
  /// In pt, this message translates to:
  /// **'Peça o código de convite ao dono da fila. Depois de enviar, o dono precisa aprovar seu acesso.'**
  String get joinOperatorIntro;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Código de convite'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCodeHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex: K7M2QX'**
  String get inviteCodeHint;

  /// No description provided for @inviteCodeLength.
  ///
  /// In pt, this message translates to:
  /// **'O código tem 6 caracteres'**
  String get inviteCodeLength;

  /// No description provided for @sendRequest.
  ///
  /// In pt, this message translates to:
  /// **'Enviar pedido'**
  String get sendRequest;

  /// No description provided for @sendRequestError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar o pedido. Tente novamente.'**
  String get sendRequestError;

  /// No description provided for @cancelRequestError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível cancelar. Tente novamente.'**
  String get cancelRequestError;

  /// No description provided for @pendingBody.
  ///
  /// In pt, this message translates to:
  /// **'O dono da fila precisa aprovar seu pedido. Esta tela atualiza sozinha.'**
  String get pendingBody;

  /// No description provided for @requestApproved.
  ///
  /// In pt, this message translates to:
  /// **'Pedido aprovado'**
  String get requestApproved;

  /// No description provided for @approvedBody.
  ///
  /// In pt, this message translates to:
  /// **'Você já pode atender esta fila.'**
  String get approvedBody;

  /// No description provided for @requestRejected.
  ///
  /// In pt, this message translates to:
  /// **'Pedido recusado'**
  String get requestRejected;

  /// No description provided for @rejectedBody.
  ///
  /// In pt, this message translates to:
  /// **'O dono da fila recusou seu pedido.'**
  String get rejectedBody;

  /// No description provided for @removedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Você foi removido'**
  String get removedTitle;

  /// No description provided for @removedBody.
  ///
  /// In pt, this message translates to:
  /// **'O dono da fila removeu seu acesso de operador.'**
  String get removedBody;

  /// No description provided for @requestNotFound.
  ///
  /// In pt, this message translates to:
  /// **'Pedido não encontrado'**
  String get requestNotFound;

  /// No description provided for @requestNotFoundBody.
  ///
  /// In pt, this message translates to:
  /// **'O pedido foi cancelado ou removido.'**
  String get requestNotFoundBody;

  /// No description provided for @openQueue.
  ///
  /// In pt, this message translates to:
  /// **'Abrir fila'**
  String get openQueue;

  /// No description provided for @cancelRequest.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar pedido'**
  String get cancelRequest;

  /// No description provided for @inviteGenerateFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível gerar um código.'**
  String get inviteGenerateFailed;

  /// No description provided for @inviteInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido.'**
  String get inviteInvalid;

  /// No description provided for @inviteInvalidOrRevoked.
  ///
  /// In pt, this message translates to:
  /// **'Código inválido ou revogado.'**
  String get inviteInvalidOrRevoked;

  /// No description provided for @inviteExpired.
  ///
  /// In pt, this message translates to:
  /// **'Código expirado. Peça um novo ao dono.'**
  String get inviteExpired;

  /// No description provided for @inviteOwnQueue.
  ///
  /// In pt, this message translates to:
  /// **'Você já é o dono desta fila.'**
  String get inviteOwnQueue;

  /// No description provided for @operatorsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Operadores'**
  String get operatorsTitle;

  /// No description provided for @pendingRequestsSection.
  ///
  /// In pt, this message translates to:
  /// **'PEDIDOS PENDENTES'**
  String get pendingRequestsSection;

  /// No description provided for @activeOperatorsSection.
  ///
  /// In pt, this message translates to:
  /// **'OPERADORES ATIVOS'**
  String get activeOperatorsSection;

  /// No description provided for @noPendingRequests.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum pedido pendente'**
  String get noPendingRequests;

  /// No description provided for @noOperatorsYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum operador ainda'**
  String get noOperatorsYet;

  /// No description provided for @inviteExplain.
  ///
  /// In pt, this message translates to:
  /// **'Quem receber o código pede acesso pelo app. Você aprova cada pedido.'**
  String get inviteExplain;

  /// No description provided for @noExpiration.
  ///
  /// In pt, this message translates to:
  /// **'Sem expiração'**
  String get noExpiration;

  /// No description provided for @validUntil.
  ///
  /// In pt, this message translates to:
  /// **'Válido até {date}'**
  String validUntil(String date);

  /// No description provided for @revokeCode.
  ///
  /// In pt, this message translates to:
  /// **'Revogar código'**
  String get revokeCode;

  /// No description provided for @previousCodeExpired.
  ///
  /// In pt, this message translates to:
  /// **'O código anterior expirou.'**
  String get previousCodeExpired;

  /// No description provided for @validity.
  ///
  /// In pt, this message translates to:
  /// **'Validade'**
  String get validity;

  /// No description provided for @validityHour.
  ///
  /// In pt, this message translates to:
  /// **'1 hora'**
  String get validityHour;

  /// No description provided for @validityDay.
  ///
  /// In pt, this message translates to:
  /// **'24 horas'**
  String get validityDay;

  /// No description provided for @validityWeek.
  ///
  /// In pt, this message translates to:
  /// **'7 dias'**
  String get validityWeek;

  /// No description provided for @generateNewCode.
  ///
  /// In pt, this message translates to:
  /// **'Gerar novo código'**
  String get generateNewCode;

  /// No description provided for @generateCode.
  ///
  /// In pt, this message translates to:
  /// **'Gerar código'**
  String get generateCode;

  /// No description provided for @reject.
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In pt, this message translates to:
  /// **'Aprovar'**
  String get approve;

  /// No description provided for @removeOperatorTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Remover operador'**
  String get removeOperatorTooltip;

  /// No description provided for @removeOperatorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover operador?'**
  String get removeOperatorTitle;

  /// No description provided for @removeOperatorBody.
  ///
  /// In pt, this message translates to:
  /// **'{name} perde o acesso à fila. Atendimentos já chamados por essa pessoa continuam na fila.'**
  String removeOperatorBody(String name);

  /// No description provided for @codeCopied.
  ///
  /// In pt, this message translates to:
  /// **'Código copiado!'**
  String get codeCopied;

  /// No description provided for @shareCodeText.
  ///
  /// In pt, this message translates to:
  /// **'Código para atender a fila \"{queue}\" no Qio: {code}\nAbra o app Qio > Entrar como operador.'**
  String shareCodeText(String queue, String code);

  /// No description provided for @tourPanelQrTitle.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe o QR code'**
  String get tourPanelQrTitle;

  /// No description provided for @tourPanelQrBody.
  ///
  /// In pt, this message translates to:
  /// **'Seus clientes escaneiam para entrar na fila, sem instalar nada.'**
  String get tourPanelQrBody;

  /// No description provided for @tourPanelCallTitle.
  ///
  /// In pt, this message translates to:
  /// **'Chame o próximo'**
  String get tourPanelCallTitle;

  /// No description provided for @tourPanelCallBody.
  ///
  /// In pt, this message translates to:
  /// **'Toque aqui para chamar a próxima pessoa da fila.'**
  String get tourPanelCallBody;

  /// No description provided for @newPersonInQueue.
  ///
  /// In pt, this message translates to:
  /// **'Nova pessoa na fila: {name}'**
  String newPersonInQueue(String name);

  /// No description provided for @newPeopleInQueue.
  ///
  /// In pt, this message translates to:
  /// **'{count} novas pessoas na fila'**
  String newPeopleInQueue(int count);

  /// No description provided for @syncError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível sincronizar a fila. Tente reabrir.'**
  String get syncError;

  /// No description provided for @accessEndedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Acesso encerrado'**
  String get accessEndedTitle;

  /// No description provided for @accessEndedBody.
  ///
  /// In pt, this message translates to:
  /// **'Você não é mais operador desta fila. O dono removeu seu acesso ou a fila foi excluída.'**
  String get accessEndedBody;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico'**
  String get historyTitle;

  /// No description provided for @reopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir'**
  String get reopen;

  /// No description provided for @pause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @queueClosedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fila fechada'**
  String get queueClosedTitle;

  /// No description provided for @noServiceInProgress.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento em andamento'**
  String get noServiceInProgress;

  /// No description provided for @closedOwnerHint.
  ///
  /// In pt, this message translates to:
  /// **'A fila está fechada. Você pode reabri-la ou excluí-la.'**
  String get closedOwnerHint;

  /// No description provided for @closedOperatorHint.
  ///
  /// In pt, this message translates to:
  /// **'A fila está fechada. Aguarde o dono reabrir.'**
  String get closedOperatorHint;

  /// No description provided for @servingByOthers.
  ///
  /// In pt, this message translates to:
  /// **'EM ATENDIMENTO POR OUTROS'**
  String get servingByOthers;

  /// No description provided for @finishService.
  ///
  /// In pt, this message translates to:
  /// **'Finalizar atendimento'**
  String get finishService;

  /// No description provided for @served.
  ///
  /// In pt, this message translates to:
  /// **'Atendido'**
  String get served;

  /// No description provided for @noShow.
  ///
  /// In pt, this message translates to:
  /// **'Não compareceu'**
  String get noShow;

  /// No description provided for @upNext.
  ///
  /// In pt, this message translates to:
  /// **'PRÓXIMOS NA FILA'**
  String get upNext;

  /// No description provided for @nobodyInQueue.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém na fila'**
  String get nobodyInQueue;

  /// No description provided for @deleteQueue.
  ///
  /// In pt, this message translates to:
  /// **'Excluir fila'**
  String get deleteQueue;

  /// No description provided for @callNext.
  ///
  /// In pt, this message translates to:
  /// **'Chamar próximo'**
  String get callNext;

  /// No description provided for @operatorsAndInvites.
  ///
  /// In pt, this message translates to:
  /// **'Operadores e convites'**
  String get operatorsAndInvites;

  /// No description provided for @qrSemantics.
  ///
  /// In pt, this message translates to:
  /// **'QR code para entrar na fila'**
  String get qrSemantics;

  /// No description provided for @scanToJoin.
  ///
  /// In pt, this message translates to:
  /// **'Escaneie para entrar na fila'**
  String get scanToJoin;

  /// No description provided for @copyLinkSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link da fila'**
  String get copyLinkSemantics;

  /// No description provided for @copyLink.
  ///
  /// In pt, this message translates to:
  /// **'Copiar link'**
  String get copyLink;

  /// No description provided for @printablePoster.
  ///
  /// In pt, this message translates to:
  /// **'Cartaz para impressão'**
  String get printablePoster;

  /// No description provided for @linkCopied.
  ///
  /// In pt, this message translates to:
  /// **'Link copiado!'**
  String get linkCopied;

  /// No description provided for @deleteQueueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir fila?'**
  String get deleteQueueTitle;

  /// No description provided for @deleteQueueBody.
  ///
  /// In pt, this message translates to:
  /// **'Essa ação é permanente. A fila e todo o histórico de atendimentos serão apagados.'**
  String get deleteQueueBody;

  /// No description provided for @nobodyCalled.
  ///
  /// In pt, this message translates to:
  /// **'Ninguém chamado'**
  String get nobodyCalled;

  /// No description provided for @callNextHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Chamar próximo\" para começar'**
  String get callNextHint;

  /// No description provided for @callingNow.
  ///
  /// In pt, this message translates to:
  /// **'CHAMANDO AGORA'**
  String get callingNow;

  /// No description provided for @waitTileSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'#{ticket} · {minutes} min'**
  String waitTileSubtitle(int ticket, int minutes);

  /// No description provided for @ticketAndName.
  ///
  /// In pt, this message translates to:
  /// **'#{ticket} {name}'**
  String ticketAndName(int ticket, String name);

  /// No description provided for @exportTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Exportar'**
  String get exportTooltip;

  /// No description provided for @exportCsv.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV'**
  String get exportCsv;

  /// No description provided for @exportPdf.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF'**
  String get exportPdf;

  /// No description provided for @nothingToExport.
  ///
  /// In pt, this message translates to:
  /// **'Nada para exportar neste filtro.'**
  String get nothingToExport;

  /// No description provided for @exportError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível exportar o histórico.'**
  String get exportError;

  /// No description provided for @loadHistoryError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar o histórico. Tente novamente.'**
  String get loadHistoryError;

  /// No description provided for @noHistoryYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento ainda'**
  String get noHistoryYet;

  /// No description provided for @noHistoryInFilter.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento neste filtro'**
  String get noHistoryInFilter;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos'**
  String get filterAll;

  /// No description provided for @periodToday.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get periodToday;

  /// No description provided for @period7Days.
  ///
  /// In pt, this message translates to:
  /// **'7 dias'**
  String get period7Days;

  /// No description provided for @periodAll.
  ///
  /// In pt, this message translates to:
  /// **'Tudo'**
  String get periodAll;

  /// No description provided for @servedPlural.
  ///
  /// In pt, this message translates to:
  /// **'Atendidos'**
  String get servedPlural;

  /// No description provided for @noShowPlural.
  ///
  /// In pt, this message translates to:
  /// **'Não compareceram'**
  String get noShowPlural;

  /// No description provided for @leftPlural.
  ///
  /// In pt, this message translates to:
  /// **'Desistiram'**
  String get leftPlural;

  /// No description provided for @avgWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera média'**
  String get avgWait;

  /// No description provided for @avgService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento médio'**
  String get avgService;

  /// No description provided for @avgRating.
  ///
  /// In pt, this message translates to:
  /// **'Avaliação média'**
  String get avgRating;

  /// No description provided for @resultLeft.
  ///
  /// In pt, this message translates to:
  /// **'Desistiu'**
  String get resultLeft;

  /// No description provided for @waitSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'espera {duration}'**
  String waitSubtitle(String duration);

  /// No description provided for @durationMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationLessThanMinute.
  ///
  /// In pt, this message translates to:
  /// **'<1 min'**
  String get durationLessThanMinute;

  /// No description provided for @csvTicket.
  ///
  /// In pt, this message translates to:
  /// **'ticket'**
  String get csvTicket;

  /// No description provided for @csvName.
  ///
  /// In pt, this message translates to:
  /// **'nome'**
  String get csvName;

  /// No description provided for @csvPhone.
  ///
  /// In pt, this message translates to:
  /// **'telefone'**
  String get csvPhone;

  /// No description provided for @csvResult.
  ///
  /// In pt, this message translates to:
  /// **'resultado'**
  String get csvResult;

  /// No description provided for @csvEntered.
  ///
  /// In pt, this message translates to:
  /// **'entrada'**
  String get csvEntered;

  /// No description provided for @csvCalled.
  ///
  /// In pt, this message translates to:
  /// **'chamado'**
  String get csvCalled;

  /// No description provided for @csvFinished.
  ///
  /// In pt, this message translates to:
  /// **'finalizado'**
  String get csvFinished;

  /// No description provided for @pdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qio - Histórico de atendimentos'**
  String get pdfTitle;

  /// No description provided for @pdfGeneratedAt.
  ///
  /// In pt, this message translates to:
  /// **'Gerado em {date}'**
  String pdfGeneratedAt(String date);

  /// No description provided for @pdfTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get pdfTotal;

  /// No description provided for @pdfNoRecords.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento no período.'**
  String get pdfNoRecords;

  /// No description provided for @colTicket.
  ///
  /// In pt, this message translates to:
  /// **'Ticket'**
  String get colTicket;

  /// No description provided for @colName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get colName;

  /// No description provided for @colPhone.
  ///
  /// In pt, this message translates to:
  /// **'Telefone'**
  String get colPhone;

  /// No description provided for @colResult.
  ///
  /// In pt, this message translates to:
  /// **'Resultado'**
  String get colResult;

  /// No description provided for @colEntered.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get colEntered;

  /// No description provided for @colCalled.
  ///
  /// In pt, this message translates to:
  /// **'Chamado'**
  String get colCalled;

  /// No description provided for @colFinished.
  ///
  /// In pt, this message translates to:
  /// **'Finalizado'**
  String get colFinished;

  /// No description provided for @posterTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cartaz do QR'**
  String get posterTitle;

  /// No description provided for @qrColor.
  ///
  /// In pt, this message translates to:
  /// **'COR DO QR'**
  String get qrColor;

  /// No description provided for @qrColorBlue.
  ///
  /// In pt, this message translates to:
  /// **'Azul'**
  String get qrColorBlue;

  /// No description provided for @qrColorBlack.
  ///
  /// In pt, this message translates to:
  /// **'Preto'**
  String get qrColorBlack;

  /// No description provided for @qrColorDarkGreen.
  ///
  /// In pt, this message translates to:
  /// **'Verde escuro'**
  String get qrColorDarkGreen;

  /// No description provided for @shareImage.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar imagem'**
  String get shareImage;

  /// No description provided for @shareImageError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível compartilhar a imagem.'**
  String get shareImageError;

  /// No description provided for @printPosterError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível imprimir o cartaz.'**
  String get printPosterError;

  /// No description provided for @skip.
  ///
  /// In pt, this message translates to:
  /// **'PULAR'**
  String get skip;

  /// No description provided for @stepOf.
  ///
  /// In pt, this message translates to:
  /// **'{index} de {total}'**
  String stepOf(int index, int total);

  /// No description provided for @tapToContinue.
  ///
  /// In pt, this message translates to:
  /// **'Toque para continuar'**
  String get tapToContinue;

  /// No description provided for @avatarLabel.
  ///
  /// In pt, this message translates to:
  /// **'Avatar: {name}'**
  String avatarLabel(String name);

  /// No description provided for @metricsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Métricas'**
  String get metricsTitle;

  /// No description provided for @metricsTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Métricas das filas'**
  String get metricsTooltip;

  /// No description provided for @metricsTotal.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos'**
  String get metricsTotal;

  /// No description provided for @peakHoursTitle.
  ///
  /// In pt, this message translates to:
  /// **'Picos de demanda'**
  String get peakHoursTitle;

  /// No description provided for @peakHoursSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Pessoas que entraram por horário'**
  String get peakHoursSubtitle;

  /// No description provided for @peakHoursTop.
  ///
  /// In pt, this message translates to:
  /// **'Horários mais cheios: {hours}'**
  String peakHoursTop(String hours);

  /// No description provided for @noPeakData.
  ///
  /// In pt, this message translates to:
  /// **'Sem dados no período'**
  String get noPeakData;

  /// No description provided for @mostActiveQueues.
  ///
  /// In pt, this message translates to:
  /// **'Filas mais ativas'**
  String get mostActiveQueues;

  /// No description provided for @queueActivityLine.
  ///
  /// In pt, this message translates to:
  /// **'{total} atendimentos · {rate}% não compareceram'**
  String queueActivityLine(int total, int rate);

  /// No description provided for @noMetricsData.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento no período'**
  String get noMetricsData;

  /// No description provided for @loadMetricsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar as métricas. Tente novamente.'**
  String get loadMetricsError;

  /// No description provided for @noQueuesYet.
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem filas'**
  String get noQueuesYet;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci a senha'**
  String get forgotPassword;

  /// No description provided for @resetEmailRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail para recuperar a senha'**
  String get resetEmailRequired;

  /// No description provided for @resetEmailSent.
  ///
  /// In pt, this message translates to:
  /// **'Se houver uma conta com esse e-mail, enviamos um link para redefinir a senha.'**
  String get resetEmailSent;

  /// No description provided for @showPassword.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar senha'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar senha'**
  String get hidePassword;

  /// No description provided for @offlineBanner.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Os dados podem estar desatualizados.'**
  String get offlineBanner;

  /// No description provided for @loadErrorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Algo deu errado'**
  String get loadErrorTitle;

  /// No description provided for @loadErrorBody.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar seus dados. Verifique a conexão e tente de novo.'**
  String get loadErrorBody;

  /// No description provided for @hapticsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Vibração'**
  String get hapticsTitle;

  /// No description provided for @hapticsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Vibrar ao chamar, finalizar e confirmar ações'**
  String get hapticsSubtitle;

  /// No description provided for @nobodyInQueueHint.
  ///
  /// In pt, this message translates to:
  /// **'Quando alguém entrar pelo QR code, aparece aqui.'**
  String get nobodyInQueueHint;

  /// No description provided for @emptyHistoryHint.
  ///
  /// In pt, this message translates to:
  /// **'Os atendimentos finalizados aparecem aqui.'**
  String get emptyHistoryHint;

  /// No description provided for @emptyMetricsHint.
  ///
  /// In pt, this message translates to:
  /// **'Escolha outro período ou aguarde os primeiros atendimentos.'**
  String get emptyMetricsHint;

  /// No description provided for @discardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Descartar alterações?'**
  String get discardTitle;

  /// No description provided for @discardBody.
  ///
  /// In pt, this message translates to:
  /// **'Você já preencheu campos. Se sair agora, vai perder o que digitou.'**
  String get discardBody;

  /// No description provided for @keepEditing.
  ///
  /// In pt, this message translates to:
  /// **'Continuar editando'**
  String get keepEditing;

  /// No description provided for @discard.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @maxWaitingLabel.
  ///
  /// In pt, this message translates to:
  /// **'Limite de pessoas esperando (opcional)'**
  String get maxWaitingLabel;

  /// No description provided for @maxWaitingHint.
  ///
  /// In pt, this message translates to:
  /// **'Sem limite'**
  String get maxWaitingHint;

  /// No description provided for @maxWaitingInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use um número de 1 a 1000'**
  String get maxWaitingInvalid;

  /// No description provided for @queueLimitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limite da fila'**
  String get queueLimitTitle;

  /// No description provided for @queueLimitNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem limite de espera'**
  String get queueLimitNone;

  /// No description provided for @queueLimitValue.
  ///
  /// In pt, this message translates to:
  /// **'Até {max} pessoas esperando'**
  String queueLimitValue(int max);

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @pauseQueueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pausar a fila'**
  String get pauseQueueTitle;

  /// No description provided for @closeQueueTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fechar a fila'**
  String get closeQueueTitle;

  /// No description provided for @statusMessageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mensagem para os clientes (opcional)'**
  String get statusMessageLabel;

  /// No description provided for @statusSuggestionBack10.
  ///
  /// In pt, this message translates to:
  /// **'Volto em 10 minutos'**
  String get statusSuggestionBack10;

  /// No description provided for @statusSuggestionBreak.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo rápido'**
  String get statusSuggestionBreak;

  /// No description provided for @statusSuggestionClosedToday.
  ///
  /// In pt, this message translates to:
  /// **'Fila encerrada por hoje'**
  String get statusSuggestionClosedToday;

  /// No description provided for @resumeAtLabel.
  ///
  /// In pt, this message translates to:
  /// **'Previsão de retorno'**
  String get resumeAtLabel;

  /// No description provided for @resumeAtNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem previsão'**
  String get resumeAtNone;

  /// No description provided for @clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// No description provided for @waitingCounter.
  ///
  /// In pt, this message translates to:
  /// **'{count}/{max} esperando'**
  String waitingCounter(int count, int max);

  /// No description provided for @callAgain.
  ///
  /// In pt, this message translates to:
  /// **'Chamar de novo'**
  String get callAgain;

  /// No description provided for @callNow.
  ///
  /// In pt, this message translates to:
  /// **'Chamar agora'**
  String get callNow;

  /// No description provided for @moveToEnd.
  ///
  /// In pt, this message translates to:
  /// **'Mover para o fim'**
  String get moveToEnd;

  /// No description provided for @moreActions.
  ///
  /// In pt, this message translates to:
  /// **'Mais ações'**
  String get moreActions;

  /// No description provided for @calledTimes.
  ///
  /// In pt, this message translates to:
  /// **'Chamado {count}x'**
  String calledTimes(int count);

  /// No description provided for @callResent.
  ///
  /// In pt, this message translates to:
  /// **'Chamada reenviada'**
  String get callResent;

  /// No description provided for @movedToEnd.
  ///
  /// In pt, this message translates to:
  /// **'{name} foi para o fim da fila'**
  String movedToEnd(String name);

  /// No description provided for @entryUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Esta pessoa já não está aguardando'**
  String get entryUnavailable;

  /// No description provided for @scheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Horário de funcionamento'**
  String get scheduleTitle;

  /// No description provided for @scheduleOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligado'**
  String get scheduleOff;

  /// No description provided for @scheduleHours.
  ///
  /// In pt, this message translates to:
  /// **'{days} · {open}–{close}'**
  String scheduleHours(String days, String open, String close);

  /// No description provided for @scheduleEnabled.
  ///
  /// In pt, this message translates to:
  /// **'Abrir e fechar automaticamente'**
  String get scheduleEnabled;

  /// No description provided for @scheduleDays.
  ///
  /// In pt, this message translates to:
  /// **'Dias'**
  String get scheduleDays;

  /// No description provided for @scheduleOpens.
  ///
  /// In pt, this message translates to:
  /// **'Abre'**
  String get scheduleOpens;

  /// No description provided for @scheduleCloses.
  ///
  /// In pt, this message translates to:
  /// **'Fecha'**
  String get scheduleCloses;

  /// No description provided for @scheduleInvalidDays.
  ///
  /// In pt, this message translates to:
  /// **'Escolha ao menos um dia'**
  String get scheduleInvalidDays;

  /// No description provided for @scheduleInvalidTime.
  ///
  /// In pt, this message translates to:
  /// **'Abertura e fechamento devem ser diferentes'**
  String get scheduleInvalidTime;

  /// No description provided for @scheduleNote.
  ///
  /// In pt, this message translates to:
  /// **'Horário de Brasília. Se você abrir, pausar ou fechar na mão, vale até a próxima abertura ou fechamento do horário.'**
  String get scheduleNote;

  /// No description provided for @linkForCustomers.
  ///
  /// In pt, this message translates to:
  /// **'Este link é para clientes. Abrindo no navegador.'**
  String get linkForCustomers;

  /// No description provided for @brandTitle.
  ///
  /// In pt, this message translates to:
  /// **'Identidade da fila'**
  String get brandTitle;

  /// No description provided for @brandSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cor e logo na página do cliente'**
  String get brandSubtitle;

  /// No description provided for @brandColorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cor'**
  String get brandColorLabel;

  /// No description provided for @brandLogoLabel.
  ///
  /// In pt, this message translates to:
  /// **'Logo'**
  String get brandLogoLabel;

  /// No description provided for @brandChooseImage.
  ///
  /// In pt, this message translates to:
  /// **'Escolher imagem'**
  String get brandChooseImage;

  /// No description provided for @brandError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar. Verifique a conexão e tente de novo.'**
  String get brandError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
