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

  /// No description provided for @deleteAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountZone.
  ///
  /// In pt, this message translates to:
  /// **'Zona de risco'**
  String get deleteAccountZone;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Apaga sua conta, suas filas, históricos, avaliações e dispositivos. Não dá para desfazer.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In pt, this message translates to:
  /// **'Todas as suas filas, o histórico de atendimentos, as avaliações, os grupos e a sua conta serão apagados de forma permanente. Quem está em uma fila sua perde a senha. Se você é operador de filas de outras pessoas, apenas o seu vínculo é removido.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Digite EXCLUIR ou o seu e-mail para confirmar'**
  String get deleteAccountConfirmLabel;

  /// No description provided for @deleteAccountPasswordLabel.
  ///
  /// In pt, this message translates to:
  /// **'Senha atual'**
  String get deleteAccountPasswordLabel;

  /// No description provided for @deleteAccountGoogleHint.
  ///
  /// In pt, this message translates to:
  /// **'Você vai confirmar sua identidade com o Google antes de excluir.'**
  String get deleteAccountGoogleHint;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Excluir definitivamente'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountProgress.
  ///
  /// In pt, this message translates to:
  /// **'Excluindo seus dados. Isso pode levar alguns instantes.'**
  String get deleteAccountProgress;

  /// No description provided for @deleteAccountReauthFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível confirmar sua identidade. Confira a senha e tente de novo.'**
  String get deleteAccountReauthFailed;

  /// No description provided for @deleteAccountError.
  ///
  /// In pt, this message translates to:
  /// **'A exclusão não terminou. Parte dos dados pode já ter sido apagada. Tente novamente para concluir.'**
  String get deleteAccountError;

  /// No description provided for @deleteAccountRetry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get deleteAccountRetry;

  /// No description provided for @deleteAccountRecentLogin.
  ///
  /// In pt, this message translates to:
  /// **'Por segurança, confirme sua identidade de novo para concluir a exclusão.'**
  String get deleteAccountRecentLogin;

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
  /// **'Toque no cartão para abrir o painel e chamar as pessoas. Pause ou mostre o QR code pelos atalhos do cartão.'**
  String get tourHomeQueueBody;

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

  /// No description provided for @analyticsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ajudar a melhorar o Qio'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Envia estatísticas anônimas de uso (sem nomes, telefones ou dados de clientes). Você pode desativar quando quiser.'**
  String get analyticsSubtitle;

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

  /// No description provided for @pushTitle.
  ///
  /// In pt, this message translates to:
  /// **'Avisos de novas entradas'**
  String get pushTitle;

  /// No description provided for @pushSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificar quando alguém entrar na fila, mesmo com o app fechado'**
  String get pushSubtitle;

  /// No description provided for @pushPromptTitle.
  ///
  /// In pt, this message translates to:
  /// **'Receber avisos?'**
  String get pushPromptTitle;

  /// No description provided for @pushPromptBody.
  ///
  /// In pt, this message translates to:
  /// **'Avisamos quando alguém entrar em uma das suas filas, mesmo com o app fechado. Você pode mudar isso depois em Minha conta.'**
  String get pushPromptBody;

  /// No description provided for @pushPromptNotNow.
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get pushPromptNotNow;

  /// No description provided for @pushPromptEnable.
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get pushPromptEnable;

  /// No description provided for @pushDenied.
  ///
  /// In pt, this message translates to:
  /// **'Permissão negada. Ative as notificações nas configurações do sistema.'**
  String get pushDenied;

  /// No description provided for @byOperatorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Por atendente'**
  String get byOperatorTitle;

  /// No description provided for @operatorFilterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as filas'**
  String get operatorFilterAll;

  /// No description provided for @ownerAttendant.
  ///
  /// In pt, this message translates to:
  /// **'Dono'**
  String get ownerAttendant;

  /// No description provided for @formerOperator.
  ///
  /// In pt, this message translates to:
  /// **'ex-operador'**
  String get formerOperator;

  /// No description provided for @noOperatorData.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum atendimento por atendente no período'**
  String get noOperatorData;

  /// No description provided for @historyTruncatedWarning.
  ///
  /// In pt, this message translates to:
  /// **'Mostrando só os {limit} registros mais recentes de uma fila; os números podem estar incompletos.'**
  String historyTruncatedWarning(int limit);

  /// No description provided for @operatorCountsLine.
  ///
  /// In pt, this message translates to:
  /// **'{served} atendidos · {noShow} não compareceram'**
  String operatorCountsLine(int served, int noShow);

  /// No description provided for @operatorDetailLine.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento médio: {avg} · Avaliação: {rating}'**
  String operatorDetailLine(String avg, String rating);

  /// No description provided for @operatorFilterLabel.
  ///
  /// In pt, this message translates to:
  /// **'Filtrar por fila'**
  String get operatorFilterLabel;

  /// No description provided for @metricsPdfTitle.
  ///
  /// In pt, this message translates to:
  /// **'Qio - Métricas das filas'**
  String get metricsPdfTitle;

  /// No description provided for @csvPeriod.
  ///
  /// In pt, this message translates to:
  /// **'período'**
  String get csvPeriod;

  /// No description provided for @csvScope.
  ///
  /// In pt, this message translates to:
  /// **'escopo por atendente'**
  String get csvScope;

  /// No description provided for @csvGeneratedAt.
  ///
  /// In pt, this message translates to:
  /// **'gerado em'**
  String get csvGeneratedAt;

  /// No description provided for @csvMetric.
  ///
  /// In pt, this message translates to:
  /// **'métrica'**
  String get csvMetric;

  /// No description provided for @csvValue.
  ///
  /// In pt, this message translates to:
  /// **'valor'**
  String get csvValue;

  /// No description provided for @csvHour.
  ///
  /// In pt, this message translates to:
  /// **'hora'**
  String get csvHour;

  /// No description provided for @csvEntries.
  ///
  /// In pt, this message translates to:
  /// **'entradas'**
  String get csvEntries;

  /// No description provided for @csvPosition.
  ///
  /// In pt, this message translates to:
  /// **'posição'**
  String get csvPosition;

  /// No description provided for @csvQueue.
  ///
  /// In pt, this message translates to:
  /// **'fila'**
  String get csvQueue;

  /// No description provided for @csvTotal.
  ///
  /// In pt, this message translates to:
  /// **'total'**
  String get csvTotal;

  /// No description provided for @csvServed.
  ///
  /// In pt, this message translates to:
  /// **'atendidos'**
  String get csvServed;

  /// No description provided for @csvNoShow.
  ///
  /// In pt, this message translates to:
  /// **'não compareceram'**
  String get csvNoShow;

  /// No description provided for @csvLeft.
  ///
  /// In pt, this message translates to:
  /// **'desistiram'**
  String get csvLeft;

  /// No description provided for @csvNoShowRatePct.
  ///
  /// In pt, this message translates to:
  /// **'taxa de não comparecimento (%)'**
  String get csvNoShowRatePct;

  /// No description provided for @csvAvgWaitMin.
  ///
  /// In pt, this message translates to:
  /// **'espera média (min)'**
  String get csvAvgWaitMin;

  /// No description provided for @csvAvgServiceMin.
  ///
  /// In pt, this message translates to:
  /// **'atendimento médio (min)'**
  String get csvAvgServiceMin;

  /// No description provided for @csvAvgRating.
  ///
  /// In pt, this message translates to:
  /// **'nota média'**
  String get csvAvgRating;

  /// No description provided for @csvRatingCount.
  ///
  /// In pt, this message translates to:
  /// **'qtd notas'**
  String get csvRatingCount;

  /// No description provided for @csvAttendant.
  ///
  /// In pt, this message translates to:
  /// **'atendente'**
  String get csvAttendant;

  /// No description provided for @exportMetricsError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível exportar as métricas.'**
  String get exportMetricsError;

  /// No description provided for @groups.
  ///
  /// In pt, this message translates to:
  /// **'Grupos'**
  String get groups;

  /// No description provided for @groupNew.
  ///
  /// In pt, this message translates to:
  /// **'Novo grupo…'**
  String get groupNew;

  /// No description provided for @groupRename.
  ///
  /// In pt, this message translates to:
  /// **'Renomear grupo'**
  String get groupRename;

  /// No description provided for @groupDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir grupo'**
  String get groupDelete;

  /// No description provided for @groupDeleteConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o grupo \"{name}\"? As filas dele ficam sem grupo.'**
  String groupDeleteConfirm(String name);

  /// No description provided for @groupNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem grupo'**
  String get groupNone;

  /// No description provided for @groupName.
  ///
  /// In pt, this message translates to:
  /// **'Nome do grupo'**
  String get groupName;

  /// No description provided for @groupLimitReached.
  ///
  /// In pt, this message translates to:
  /// **'Limite de {max} grupos atingido.'**
  String groupLimitReached(int max);

  /// No description provided for @queueLimitReached.
  ///
  /// In pt, this message translates to:
  /// **'Limite de {max} filas atingido. Exclua uma fila para criar outra.'**
  String queueLimitReached(int max);

  /// No description provided for @groupLabel.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get groupLabel;

  /// No description provided for @groupsEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum grupo ainda. Crie um para organizar suas filas.'**
  String get groupsEmpty;

  /// No description provided for @groupPermissionDenied.
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão para alterar grupos. Atualize o app e tente de novo.'**
  String get groupPermissionDenied;

  /// No description provided for @metricsScopeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Escopo das métricas'**
  String get metricsScopeLabel;

  /// No description provided for @metricsScopeAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas as filas'**
  String get metricsScopeAll;

  /// No description provided for @metricsScopeGroup.
  ///
  /// In pt, this message translates to:
  /// **'Grupo: {name}'**
  String metricsScopeGroup(String name);

  /// No description provided for @metricsScopeQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila: {name}'**
  String metricsScopeQueue(String name);

  /// No description provided for @groupCompareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comparativo entre filas do grupo'**
  String get groupCompareTitle;

  /// No description provided for @groupCompareLine.
  ///
  /// In pt, this message translates to:
  /// **'{total} atendimentos · espera {wait} · {rate}% não compareceram · nota {rating}'**
  String groupCompareLine(int total, String wait, int rate, String rating);

  /// No description provided for @csvDataScope.
  ///
  /// In pt, this message translates to:
  /// **'escopo das métricas'**
  String get csvDataScope;

  /// No description provided for @groupsUnavailable.
  ///
  /// In pt, this message translates to:
  /// **'Grupos indisponíveis. Atualize o app ou as regras do Firestore.'**
  String get groupsUnavailable;

  /// No description provided for @alertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas operacionais'**
  String get alertsTitle;

  /// No description provided for @alertsEnable.
  ///
  /// In pt, this message translates to:
  /// **'Receber alertas desta fila'**
  String get alertsEnable;

  /// No description provided for @alertsWaitLimit.
  ///
  /// In pt, this message translates to:
  /// **'Espera estimada acima de'**
  String get alertsWaitLimit;

  /// No description provided for @alertsNoShowLimit.
  ///
  /// In pt, this message translates to:
  /// **'Não comparecimento hoje a partir de'**
  String get alertsNoShowLimit;

  /// No description provided for @alertsIdleLimit.
  ///
  /// In pt, this message translates to:
  /// **'Fila parada com gente esperando por mais de'**
  String get alertsIdleLimit;

  /// No description provided for @alertsCooldown.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo mínimo entre alertas'**
  String get alertsCooldown;

  /// No description provided for @alertsPushOff.
  ///
  /// In pt, this message translates to:
  /// **'As notificações estão desativadas. Ative-as para receber os alertas.'**
  String get alertsPushOff;

  /// No description provided for @alertsOff.
  ///
  /// In pt, this message translates to:
  /// **'Desligado'**
  String get alertsOff;

  /// No description provided for @alertsActive.
  ///
  /// In pt, this message translates to:
  /// **'{count} regras ativas'**
  String alertsActive(int count);

  /// No description provided for @alertsMinutes.
  ///
  /// In pt, this message translates to:
  /// **'{n} min'**
  String alertsMinutes(int n);

  /// No description provided for @alertsPercent.
  ///
  /// In pt, this message translates to:
  /// **'{n}%'**
  String alertsPercent(int n);

  /// No description provided for @alertsNoRule.
  ///
  /// In pt, this message translates to:
  /// **'Ative ao menos uma regra para receber alertas.'**
  String get alertsNoRule;

  /// No description provided for @alertsNotify.
  ///
  /// In pt, this message translates to:
  /// **'Receber alertas nesta conta'**
  String get alertsNotify;

  /// No description provided for @waitDistributionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Espera e chamadas'**
  String get waitDistributionTitle;

  /// No description provided for @medianWait.
  ///
  /// In pt, this message translates to:
  /// **'Mediana'**
  String get medianWait;

  /// No description provided for @p90Wait.
  ///
  /// In pt, this message translates to:
  /// **'P90'**
  String get p90Wait;

  /// No description provided for @waitBucketUnder5.
  ///
  /// In pt, this message translates to:
  /// **'Menos de 5 min'**
  String get waitBucketUnder5;

  /// No description provided for @waitBucket5to15.
  ///
  /// In pt, this message translates to:
  /// **'5–15 min'**
  String get waitBucket5to15;

  /// No description provided for @waitBucket15to30.
  ///
  /// In pt, this message translates to:
  /// **'15–30 min'**
  String get waitBucket15to30;

  /// No description provided for @waitBucketOver30.
  ///
  /// In pt, this message translates to:
  /// **'Mais de 30 min'**
  String get waitBucketOver30;

  /// No description provided for @recallsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Re-chamadas'**
  String get recallsTitle;

  /// No description provided for @skipsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Movidos ao fim'**
  String get skipsTitle;

  /// No description provided for @recallsStat.
  ///
  /// In pt, this message translates to:
  /// **'{entries} entradas de {total} ({pct}%) · {recalls} re-chamadas'**
  String recallsStat(int entries, int total, int pct, int recalls);

  /// No description provided for @skipsStat.
  ///
  /// In pt, this message translates to:
  /// **'{entries} entradas de {total} · {skips} movidos ao fim'**
  String skipsStat(int entries, int total, int skips);

  /// No description provided for @csvWaitSamples.
  ///
  /// In pt, this message translates to:
  /// **'amostras de espera'**
  String get csvWaitSamples;

  /// No description provided for @csvMedianWaitMin.
  ///
  /// In pt, this message translates to:
  /// **'mediana (min)'**
  String get csvMedianWaitMin;

  /// No description provided for @csvP90WaitMin.
  ///
  /// In pt, this message translates to:
  /// **'P90 (min)'**
  String get csvP90WaitMin;

  /// No description provided for @csvWaitRange.
  ///
  /// In pt, this message translates to:
  /// **'faixa de espera'**
  String get csvWaitRange;

  /// No description provided for @csvCalledEntries.
  ///
  /// In pt, this message translates to:
  /// **'entradas chamadas'**
  String get csvCalledEntries;

  /// No description provided for @csvRecallsTotal.
  ///
  /// In pt, this message translates to:
  /// **'re-chamadas'**
  String get csvRecallsTotal;

  /// No description provided for @csvRecalledEntries.
  ///
  /// In pt, this message translates to:
  /// **'entradas com re-chamada'**
  String get csvRecalledEntries;

  /// No description provided for @csvRecallRatePct.
  ///
  /// In pt, this message translates to:
  /// **'entradas com re-chamada sobre chamadas (%)'**
  String get csvRecallRatePct;

  /// No description provided for @csvSkipsTotal.
  ///
  /// In pt, this message translates to:
  /// **'movidos ao fim'**
  String get csvSkipsTotal;

  /// No description provided for @csvSkippedEntries.
  ///
  /// In pt, this message translates to:
  /// **'entradas movidas ao fim'**
  String get csvSkippedEntries;

  /// No description provided for @p90Insufficient.
  ///
  /// In pt, this message translates to:
  /// **'amostras insuficientes'**
  String get p90Insufficient;

  /// No description provided for @weekdayDemandTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dias de maior movimento'**
  String get weekdayDemandTitle;

  /// No description provided for @heatmapTitle.
  ///
  /// In pt, this message translates to:
  /// **'Mapa de calor: dia × hora'**
  String get heatmapTitle;

  /// No description provided for @demandPeakSummary.
  ///
  /// In pt, this message translates to:
  /// **'Pico: {day}, {from}–{to}'**
  String demandPeakSummary(String day, String from, String to);

  /// No description provided for @heatmapCellSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{day}, {hour}: {count, plural, =1{1 chegada} other{{count} chegadas}}'**
  String heatmapCellSemantics(String day, String hour, int count);

  /// No description provided for @csvWeekday.
  ///
  /// In pt, this message translates to:
  /// **'dia'**
  String get csvWeekday;

  /// No description provided for @csvArrivals.
  ///
  /// In pt, this message translates to:
  /// **'chegadas'**
  String get csvArrivals;

  /// No description provided for @heatmapLegendLess.
  ///
  /// In pt, this message translates to:
  /// **'menos'**
  String get heatmapLegendLess;

  /// No description provided for @heatmapLegendMore.
  ///
  /// In pt, this message translates to:
  /// **'mais'**
  String get heatmapLegendMore;

  /// No description provided for @weekdayChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Chegadas por dia: {details}'**
  String weekdayChartSemantics(String details);

  /// No description provided for @period30Days.
  ///
  /// In pt, this message translates to:
  /// **'30 dias'**
  String get period30Days;

  /// No description provided for @periodCustom.
  ///
  /// In pt, this message translates to:
  /// **'Personalizado'**
  String get periodCustom;

  /// No description provided for @deltaUp.
  ///
  /// In pt, this message translates to:
  /// **'▲ {pct}%'**
  String deltaUp(String pct);

  /// No description provided for @deltaDown.
  ///
  /// In pt, this message translates to:
  /// **'▼ {pct}%'**
  String deltaDown(String pct);

  /// No description provided for @deltaSame.
  ///
  /// In pt, this message translates to:
  /// **'= estável'**
  String get deltaSame;

  /// No description provided for @deltaPoints.
  ///
  /// In pt, this message translates to:
  /// **'{pp} p.p.'**
  String deltaPoints(String pp);

  /// No description provided for @deltaRose.
  ///
  /// In pt, this message translates to:
  /// **'subiu'**
  String get deltaRose;

  /// No description provided for @deltaFell.
  ///
  /// In pt, this message translates to:
  /// **'caiu'**
  String get deltaFell;

  /// No description provided for @deltaVsPrevious.
  ///
  /// In pt, this message translates to:
  /// **'vs. período anterior'**
  String get deltaVsPrevious;

  /// No description provided for @trendTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tendência diária'**
  String get trendTitle;

  /// No description provided for @trendSeriesTotal.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos por dia'**
  String get trendSeriesTotal;

  /// No description provided for @trendSeriesWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera média'**
  String get trendSeriesWait;

  /// No description provided for @trendSeriesNoShow.
  ///
  /// In pt, this message translates to:
  /// **'Não comparecimento'**
  String get trendSeriesNoShow;

  /// No description provided for @trendSummary.
  ///
  /// In pt, this message translates to:
  /// **'Média de {avg} por dia, pico em {peakDay}'**
  String trendSummary(String avg, String peakDay);

  /// No description provided for @csvDate.
  ///
  /// In pt, this message translates to:
  /// **'data'**
  String get csvDate;

  /// No description provided for @csvCompareTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comparativo com o período anterior'**
  String get csvCompareTitle;

  /// No description provided for @csvCurrent.
  ///
  /// In pt, this message translates to:
  /// **'atual'**
  String get csvCurrent;

  /// No description provided for @csvPrevious.
  ///
  /// In pt, this message translates to:
  /// **'anterior'**
  String get csvPrevious;

  /// No description provided for @csvDeltaPct.
  ///
  /// In pt, this message translates to:
  /// **'variação (%)'**
  String get csvDeltaPct;

  /// No description provided for @csvDeltaPoints.
  ///
  /// In pt, this message translates to:
  /// **'variação (p.p.)'**
  String get csvDeltaPoints;

  /// No description provided for @pdfVsPrevious.
  ///
  /// In pt, this message translates to:
  /// **'vs. anterior'**
  String get pdfVsPrevious;

  /// No description provided for @customRangeLimited.
  ///
  /// In pt, this message translates to:
  /// **'Intervalo limitado a {days} dias'**
  String customRangeLimited(int days);

  /// No description provided for @deltaPointsUp.
  ///
  /// In pt, this message translates to:
  /// **'▲ {pp} p.p.'**
  String deltaPointsUp(String pp);

  /// No description provided for @deltaPointsDown.
  ///
  /// In pt, this message translates to:
  /// **'▼ {pp} p.p.'**
  String deltaPointsDown(String pp);

  /// No description provided for @trendToggleWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera'**
  String get trendToggleWait;

  /// No description provided for @trendToggleNoShow.
  ///
  /// In pt, this message translates to:
  /// **'No-show'**
  String get trendToggleNoShow;

  /// No description provided for @trendMax.
  ///
  /// In pt, this message translates to:
  /// **'máx. {value}'**
  String trendMax(String value);

  /// No description provided for @trendDaySummary.
  ///
  /// In pt, this message translates to:
  /// **'{day}: {count} atendimentos, {series} {value}'**
  String trendDaySummary(String day, int count, String series, String value);

  /// No description provided for @queueModeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modo da fila'**
  String get queueModeLabel;

  /// No description provided for @modeQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila por chegada'**
  String get modeQueue;

  /// No description provided for @modeSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Hora marcada'**
  String get modeSchedule;

  /// No description provided for @slotsEditorTitle.
  ///
  /// In pt, this message translates to:
  /// **'Horários'**
  String get slotsEditorTitle;

  /// No description provided for @slotsEditorHint.
  ///
  /// In pt, this message translates to:
  /// **'Fuso America/Sao_Paulo; repetem todo dia'**
  String get slotsEditorHint;

  /// No description provided for @slotTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get slotTime;

  /// No description provided for @slotCapacity.
  ///
  /// In pt, this message translates to:
  /// **'Vagas: {count}'**
  String slotCapacity(int count);

  /// No description provided for @addSlot.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar horário'**
  String get addSlot;

  /// No description provided for @removeSlot.
  ///
  /// In pt, this message translates to:
  /// **'Remover horário'**
  String get removeSlot;

  /// No description provided for @slotsRequired.
  ///
  /// In pt, this message translates to:
  /// **'Adicione ao menos um horário'**
  String get slotsRequired;

  /// No description provided for @slotsDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Há horários repetidos'**
  String get slotsDuplicate;

  /// No description provided for @slotsTooMany.
  ///
  /// In pt, this message translates to:
  /// **'No máximo {max} horários'**
  String slotsTooMany(int max);

  /// No description provided for @slotsInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Horário ou vagas inválidos'**
  String get slotsInvalid;

  /// No description provided for @slotsOutsideSchedule.
  ///
  /// In pt, this message translates to:
  /// **'Fora do horário de funcionamento: {time}'**
  String slotsOutsideSchedule(String time);

  /// No description provided for @slotsTileSummary.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 horário} other{{count} horários}}'**
  String slotsTileSummary(int count);

  /// No description provided for @waitTileSlot.
  ///
  /// In pt, this message translates to:
  /// **'Horário {time}'**
  String waitTileSlot(String time);

  /// No description provided for @slotTimeChangeWarning.
  ///
  /// In pt, this message translates to:
  /// **'Quem já entrou neste horário continua na vaga antiga; as vagas ocupadas seguem contando.'**
  String get slotTimeChangeWarning;

  /// No description provided for @editQueue.
  ///
  /// In pt, this message translates to:
  /// **'Editar fila'**
  String get editQueue;

  /// No description provided for @editQueueHint.
  ///
  /// In pt, this message translates to:
  /// **'Nome, descrição e tempo médio'**
  String get editQueueHint;

  /// No description provided for @queueUpdated.
  ///
  /// In pt, this message translates to:
  /// **'Fila atualizada'**
  String get queueUpdated;

  /// No description provided for @duplicateQueue.
  ///
  /// In pt, this message translates to:
  /// **'Duplicar fila'**
  String get duplicateQueue;

  /// No description provided for @duplicateQueueHint.
  ///
  /// In pt, this message translates to:
  /// **'Copia limite, horário, cor, modo, grupo e alertas'**
  String get duplicateQueueHint;

  /// No description provided for @duplicateQueueCopyWord.
  ///
  /// In pt, this message translates to:
  /// **'cópia'**
  String get duplicateQueueCopyWord;

  /// No description provided for @queueDuplicated.
  ///
  /// In pt, this message translates to:
  /// **'Fila duplicada'**
  String get queueDuplicated;

  /// No description provided for @advancedOptions.
  ///
  /// In pt, this message translates to:
  /// **'Opções avançadas'**
  String get advancedOptions;

  /// No description provided for @queueNameTooLong.
  ///
  /// In pt, this message translates to:
  /// **'No máximo 60 caracteres'**
  String get queueNameTooLong;

  /// No description provided for @descriptionTooLong.
  ///
  /// In pt, this message translates to:
  /// **'No máximo 300 caracteres'**
  String get descriptionTooLong;

  /// No description provided for @avgServiceInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Informe de 1 a 240 minutos'**
  String get avgServiceInvalid;

  /// No description provided for @avgServiceAutoHint.
  ///
  /// In pt, this message translates to:
  /// **'O tempo manual só vale até existir a estimativa automática, calculada a partir dos atendimentos.'**
  String get avgServiceAutoHint;

  /// No description provided for @savingQueue.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get savingQueue;

  /// No description provided for @actionErrorOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão. Verifique a internet e tente novamente.'**
  String get actionErrorOffline;

  /// No description provided for @actionErrorAccessEnded.
  ///
  /// In pt, this message translates to:
  /// **'Acesso encerrado ou sem permissão para esta ação.'**
  String get actionErrorAccessEnded;

  /// No description provided for @actionErrorConflict.
  ///
  /// In pt, this message translates to:
  /// **'A fila mudou. Tente de novo.'**
  String get actionErrorConflict;

  /// No description provided for @undo.
  ///
  /// In pt, this message translates to:
  /// **'Desfazer'**
  String get undo;

  /// No description provided for @finishedServedUndo.
  ///
  /// In pt, this message translates to:
  /// **'{name} marcado como atendido'**
  String finishedServedUndo(String name);

  /// No description provided for @finishedNoShowUndo.
  ///
  /// In pt, this message translates to:
  /// **'{name} marcado como não compareceu'**
  String finishedNoShowUndo(String name);

  /// No description provided for @queueSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações da fila'**
  String get queueSettingsTitle;

  /// No description provided for @queueQrShortcut.
  ///
  /// In pt, this message translates to:
  /// **'QR code da fila'**
  String get queueQrShortcut;

  /// No description provided for @queueQrTitle.
  ///
  /// In pt, this message translates to:
  /// **'QR code'**
  String get queueQrTitle;

  /// No description provided for @queueGoneNotice.
  ///
  /// In pt, this message translates to:
  /// **'Esta fila não existe mais'**
  String get queueGoneNotice;

  /// No description provided for @tourPanelSettingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'QR code e configurações'**
  String get tourPanelSettingsTitle;

  /// No description provided for @tourPanelSettingsBody.
  ///
  /// In pt, this message translates to:
  /// **'Toque na engrenagem para ver o QR code e ajustar a fila.'**
  String get tourPanelSettingsBody;

  /// No description provided for @tourHomeAccountTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sua conta e convites'**
  String get tourHomeAccountTitle;

  /// No description provided for @tourHomeAccountBody.
  ///
  /// In pt, this message translates to:
  /// **'Aqui ficam sua conta e a opção de entrar como operador com um código de convite.'**
  String get tourHomeAccountBody;

  /// No description provided for @quickQr.
  ///
  /// In pt, this message translates to:
  /// **'QR code'**
  String get quickQr;

  /// No description provided for @quickPauseLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pausar fila {name}'**
  String quickPauseLabel(String name);

  /// No description provided for @quickReopenLabel.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir fila {name}'**
  String quickReopenLabel(String name);

  /// No description provided for @quickQrLabel.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar QR code da fila {name}'**
  String quickQrLabel(String name);

  /// No description provided for @searchQueuesHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar fila pelo nome'**
  String get searchQueuesHint;

  /// No description provided for @sortQueues.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar filas'**
  String get sortQueues;

  /// No description provided for @sortByName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get sortByName;

  /// No description provided for @sortByRecent.
  ///
  /// In pt, this message translates to:
  /// **'Mais recentes'**
  String get sortByRecent;

  /// No description provided for @sortByWaiting.
  ///
  /// In pt, this message translates to:
  /// **'Mais espera'**
  String get sortByWaiting;

  /// No description provided for @noQueuesMatch.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila encontrada'**
  String get noQueuesMatch;

  /// No description provided for @addPerson.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pessoa'**
  String get addPerson;

  /// No description provided for @addPersonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar pessoa à fila'**
  String get addPersonTitle;

  /// No description provided for @addPersonHint.
  ///
  /// In pt, this message translates to:
  /// **'Para quem está no balcão e não usa o QR code.'**
  String get addPersonHint;

  /// No description provided for @manualPhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone (opcional)'**
  String get manualPhoneLabel;

  /// No description provided for @manualPhoneInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use o formato (00) 00000-0000'**
  String get manualPhoneInvalid;

  /// No description provided for @manualNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome com até 60 caracteres'**
  String get manualNameRequired;

  /// No description provided for @manualSlotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get manualSlotLabel;

  /// No description provided for @manualSlotOption.
  ///
  /// In pt, this message translates to:
  /// **'{time} ({capacity} vagas)'**
  String manualSlotOption(String time, int capacity);

  /// No description provided for @manualSlotRequiredField.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um horário'**
  String get manualSlotRequiredField;

  /// No description provided for @manualAddConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get manualAddConfirm;

  /// No description provided for @manualAdded.
  ///
  /// In pt, this message translates to:
  /// **'{name} entrou na fila com a senha {ticket}'**
  String manualAdded(String name, int ticket);

  /// No description provided for @manualBadge.
  ///
  /// In pt, this message translates to:
  /// **'Balcão'**
  String get manualBadge;

  /// No description provided for @manualAddQueueFull.
  ///
  /// In pt, this message translates to:
  /// **'A fila está lotada no momento.'**
  String get manualAddQueueFull;

  /// No description provided for @manualAddSlotFull.
  ///
  /// In pt, this message translates to:
  /// **'Este horário está lotado.'**
  String get manualAddSlotFull;

  /// No description provided for @manualAddSlotRequired.
  ///
  /// In pt, this message translates to:
  /// **'Escolha um horário válido.'**
  String get manualAddSlotRequired;

  /// No description provided for @manualAddSlotPassed.
  ///
  /// In pt, this message translates to:
  /// **'Este horário já passou.'**
  String get manualAddSlotPassed;

  /// No description provided for @manualAddNotOpen.
  ///
  /// In pt, this message translates to:
  /// **'A fila precisa estar aberta para adicionar pessoas.'**
  String get manualAddNotOpen;

  /// No description provided for @manualAddInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Confira o nome e o telefone informados.'**
  String get manualAddInvalid;

  /// No description provided for @manualAddRateLimited.
  ///
  /// In pt, this message translates to:
  /// **'Muitas adições em pouco tempo. Aguarde alguns minutos.'**
  String get manualAddRateLimited;

  /// No description provided for @manualAddPhoneDuplicate.
  ///
  /// In pt, this message translates to:
  /// **'Este telefone já está na fila.'**
  String get manualAddPhoneDuplicate;

  /// No description provided for @callPhoneTooltip.
  ///
  /// In pt, this message translates to:
  /// **'Ligar para {name}'**
  String callPhoneTooltip(String name);

  /// No description provided for @callPhoneFailed.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o discador'**
  String get callPhoneFailed;

  /// No description provided for @privacyPolicy.
  ///
  /// In pt, this message translates to:
  /// **'Política de privacidade'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In pt, this message translates to:
  /// **'Termos de uso'**
  String get termsOfUse;

  /// No description provided for @posterSize.
  ///
  /// In pt, this message translates to:
  /// **'TAMANHO DO CARTAZ'**
  String get posterSize;

  /// No description provided for @posterSizeA4.
  ///
  /// In pt, this message translates to:
  /// **'A4'**
  String get posterSizeA4;

  /// No description provided for @posterSizeA5.
  ///
  /// In pt, this message translates to:
  /// **'A5'**
  String get posterSizeA5;

  /// No description provided for @posterSizeTable.
  ///
  /// In pt, this message translates to:
  /// **'Cartão de mesa (10×15 cm)'**
  String get posterSizeTable;

  /// No description provided for @posterHeadlineLabel.
  ///
  /// In pt, this message translates to:
  /// **'Frase no cartaz (opcional)'**
  String get posterHeadlineLabel;

  /// No description provided for @posterHeadlineHint.
  ///
  /// In pt, this message translates to:
  /// **'Ex.: Peça seu lugar sem esperar em pé'**
  String get posterHeadlineHint;

  /// No description provided for @posterHeadlineInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use até 60 caracteres.'**
  String get posterHeadlineInvalid;

  /// No description provided for @sharePdf.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar PDF'**
  String get sharePdf;

  /// No description provided for @sharePdfError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível compartilhar o PDF.'**
  String get sharePdfError;

  /// No description provided for @posterPreviewSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Prévia do cartaz em {size}'**
  String posterPreviewSemantics(String size);

  /// No description provided for @slugTitle.
  ///
  /// In pt, this message translates to:
  /// **'Link curto'**
  String get slugTitle;

  /// No description provided for @slugNone.
  ///
  /// In pt, this message translates to:
  /// **'Não definido'**
  String get slugNone;

  /// No description provided for @slugRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover link curto'**
  String get slugRemove;

  /// No description provided for @slugDialogLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nome do link'**
  String get slugDialogLabel;

  /// No description provided for @slugDialogHint.
  ///
  /// In pt, this message translates to:
  /// **'minha-loja'**
  String get slugDialogHint;

  /// No description provided for @slugPreview.
  ///
  /// In pt, this message translates to:
  /// **'Link: {url}'**
  String slugPreview(String url);

  /// No description provided for @slugInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Use de 3 a 40 letras minúsculas, números ou hífen, sem hífen no início ou no fim.'**
  String get slugInvalid;

  /// No description provided for @slugReservedError.
  ///
  /// In pt, this message translates to:
  /// **'Esse nome é reservado. Escolha outro.'**
  String get slugReservedError;

  /// No description provided for @slugTakenError.
  ///
  /// In pt, this message translates to:
  /// **'Esse link já está em uso. Escolha outro.'**
  String get slugTakenError;

  /// No description provided for @slugSaved.
  ///
  /// In pt, this message translates to:
  /// **'Link curto salvo'**
  String get slugSaved;

  /// No description provided for @slugRemoved.
  ///
  /// In pt, this message translates to:
  /// **'Link curto removido'**
  String get slugRemoved;

  /// No description provided for @slugReleaseNotice.
  ///
  /// In pt, this message translates to:
  /// **'Trocar o link invalida os QRs impressos com o link antigo. O link antigo fica reservado por 30 dias para você.'**
  String get slugReleaseNotice;

  /// No description provided for @posterNameLossy.
  ///
  /// In pt, this message translates to:
  /// **'Alguns caracteres do texto não existem na fonte do PDF e serão omitidos ou trocados.'**
  String get posterNameLossy;

  /// No description provided for @posterNameFallback.
  ///
  /// In pt, this message translates to:
  /// **'Fila'**
  String get posterNameFallback;

  /// No description provided for @exportCsvWithPhone.
  ///
  /// In pt, this message translates to:
  /// **'Exportar CSV com telefone'**
  String get exportCsvWithPhone;

  /// No description provided for @exportPdfWithPhone.
  ///
  /// In pt, this message translates to:
  /// **'Exportar PDF com telefone'**
  String get exportPdfWithPhone;

  /// No description provided for @exportPhoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'Incluir telefone?'**
  String get exportPhoneTitle;

  /// No description provided for @exportPhoneWarning.
  ///
  /// In pt, this message translates to:
  /// **'O telefone é dado pessoal (LGPD). Por padrão a exportação não o inclui. Inclua apenas se precisar e proteja o arquivo.'**
  String get exportPhoneWarning;

  /// No description provided for @exportPhoneConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Incluir telefone'**
  String get exportPhoneConfirm;

  /// No description provided for @anonymizePhoneTitle.
  ///
  /// In pt, this message translates to:
  /// **'Não guardar telefone no histórico'**
  String get anonymizePhoneTitle;

  /// No description provided for @anonymizePhoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Ao concluir um atendimento, o telefone não é salvo no histórico.'**
  String get anonymizePhoneHint;

  /// No description provided for @expiryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Expirar entradas esquecidas'**
  String get expiryTitle;

  /// No description provided for @expiryHint.
  ///
  /// In pt, this message translates to:
  /// **'Remove da fila quem ficou aguardando sem atividade. Não afeta quem já foi chamado.'**
  String get expiryHint;

  /// No description provided for @expiryAfterHours.
  ///
  /// In pt, this message translates to:
  /// **'Expirar após {hours} h'**
  String expiryAfterHours(int hours);

  /// No description provided for @expiryClearOnClose.
  ///
  /// In pt, this message translates to:
  /// **'Limpar a fila ao fechar por horário'**
  String get expiryClearOnClose;

  /// No description provided for @expiryResetTicketDaily.
  ///
  /// In pt, this message translates to:
  /// **'Reiniciar a senha todo dia'**
  String get expiryResetTicketDaily;

  /// No description provided for @expiryResetTicketDailyHint.
  ///
  /// In pt, this message translates to:
  /// **'Zera na primeira vez em que a fila ficar vazia a cada novo dia.'**
  String get expiryResetTicketDailyHint;

  /// No description provided for @dataSubjectTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados de um cliente'**
  String get dataSubjectTitle;

  /// No description provided for @dataSubjectSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atenda pedidos de acesso, correção ou eliminação de dados feitos por um cliente (LGPD).'**
  String get dataSubjectSubtitle;

  /// No description provided for @dataSubjectPhoneLabel.
  ///
  /// In pt, this message translates to:
  /// **'Telefone do cliente'**
  String get dataSubjectPhoneLabel;

  /// No description provided for @dataSubjectSearch.
  ///
  /// In pt, this message translates to:
  /// **'Buscar'**
  String get dataSubjectSearch;

  /// No description provided for @dataSubjectNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dado encontrado para este telefone nas suas filas.'**
  String get dataSubjectNone;

  /// No description provided for @dataSubjectFound.
  ///
  /// In pt, this message translates to:
  /// **'Encontrado em {count} fila(s)'**
  String dataSubjectFound(int count);

  /// No description provided for @dataSubjectQueueCounts.
  ///
  /// In pt, this message translates to:
  /// **'{history} no histórico, {feedback} avaliações, {entries} na fila agora'**
  String dataSubjectQueueCounts(int history, int feedback, int entries);

  /// No description provided for @dataSubjectPeriod.
  ///
  /// In pt, this message translates to:
  /// **'De {from} a {to}'**
  String dataSubjectPeriod(String from, String to);

  /// No description provided for @dataSubjectExport.
  ///
  /// In pt, this message translates to:
  /// **'Exportar dados (CSV)'**
  String get dataSubjectExport;

  /// No description provided for @dataSubjectExportTruncated.
  ///
  /// In pt, this message translates to:
  /// **'A exportação foi limitada aos primeiros 5000 registros.'**
  String get dataSubjectExportTruncated;

  /// No description provided for @dataSubjectAnonymize.
  ///
  /// In pt, this message translates to:
  /// **'Anonimizar'**
  String get dataSubjectAnonymize;

  /// No description provided for @dataSubjectDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get dataSubjectDelete;

  /// No description provided for @dataSubjectConfirmTitleAnonymize.
  ///
  /// In pt, this message translates to:
  /// **'Anonimizar dados deste cliente?'**
  String get dataSubjectConfirmTitleAnonymize;

  /// No description provided for @dataSubjectConfirmTitleDelete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir dados deste cliente?'**
  String get dataSubjectConfirmTitleDelete;

  /// No description provided for @dataSubjectConfirmBodyAnonymize.
  ///
  /// In pt, this message translates to:
  /// **'O nome vira \"Anônimo\", o telefone é removido do histórico e os comentários de avaliação são apagados. Se o cliente estiver em alguma fila agora, ele é removido. Não dá para desfazer.'**
  String get dataSubjectConfirmBodyAnonymize;

  /// No description provided for @dataSubjectConfirmBodyDelete.
  ///
  /// In pt, this message translates to:
  /// **'Apaga o histórico e as avaliações deste telefone e remove o cliente de qualquer fila ativa. Não dá para desfazer.'**
  String get dataSubjectConfirmBodyDelete;

  /// No description provided for @dataSubjectConfirmLabel.
  ///
  /// In pt, this message translates to:
  /// **'Digite o telefone de novo para confirmar'**
  String get dataSubjectConfirmLabel;

  /// No description provided for @dataSubjectConfirmButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar'**
  String get dataSubjectConfirmButton;

  /// No description provided for @dataSubjectDone.
  ///
  /// In pt, this message translates to:
  /// **'Concluído: {count} registro(s) tratado(s).'**
  String dataSubjectDone(int count);

  /// No description provided for @dataSubjectPartial.
  ///
  /// In pt, this message translates to:
  /// **'Alguns registros não foram tratados. Busque de novo e tente outra vez.'**
  String get dataSubjectPartial;

  /// No description provided for @dataSubjectRateLimited.
  ///
  /// In pt, this message translates to:
  /// **'Muitas consultas seguidas. Aguarde um pouco e tente de novo.'**
  String get dataSubjectRateLimited;

  /// No description provided for @dataSubjectAuditNote.
  ///
  /// In pt, this message translates to:
  /// **'Cada consulta fica registrada para auditoria, sem nome nem telefone.'**
  String get dataSubjectAuditNote;

  /// No description provided for @dataSubjectReauthTitle.
  ///
  /// In pt, this message translates to:
  /// **'Confirme sua identidade'**
  String get dataSubjectReauthTitle;

  /// No description provided for @dataSubjectReauthHint.
  ///
  /// In pt, this message translates to:
  /// **'Você vai confirmar sua identidade com o Google.'**
  String get dataSubjectReauthHint;

  /// No description provided for @dataSubjectReauthButton.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar identidade'**
  String get dataSubjectReauthButton;

  /// No description provided for @cqStepOf.
  ///
  /// In pt, this message translates to:
  /// **'Passo {current} de {total}'**
  String cqStepOf(int current, int total);

  /// No description provided for @cqContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get cqContinue;

  /// No description provided for @cqSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get cqSkip;

  /// No description provided for @cqQuickCreate.
  ///
  /// In pt, this message translates to:
  /// **'Criar agora'**
  String get cqQuickCreate;

  /// No description provided for @cqMoreDetails.
  ///
  /// In pt, this message translates to:
  /// **'Mais detalhes'**
  String get cqMoreDetails;

  /// No description provided for @cqNameTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como se chama a fila?'**
  String get cqNameTitle;

  /// No description provided for @cqNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Só o nome já basta. Você ajusta o resto depois no painel.'**
  String get cqNameHint;

  /// No description provided for @cqModeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como as pessoas entram?'**
  String get cqModeTitle;

  /// No description provided for @cqModeQueueHint.
  ///
  /// In pt, this message translates to:
  /// **'Quem chega entra no fim da fila.'**
  String get cqModeQueueHint;

  /// No description provided for @cqModeScheduleHint.
  ///
  /// In pt, this message translates to:
  /// **'Cada pessoa escolhe um dos horários que você define.'**
  String get cqModeScheduleHint;

  /// No description provided for @cqSuggestionsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sugestões de horários'**
  String get cqSuggestionsTitle;

  /// No description provided for @cqSuggestEvery30.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar horários a cada 30 min, das 9h às 17h'**
  String get cqSuggestEvery30;

  /// No description provided for @cqSuggestEveryHour.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar horários a cada hora, das 9h às 17h'**
  String get cqSuggestEveryHour;

  /// No description provided for @cqCapacityTitle.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio e limite de espera'**
  String get cqCapacityTitle;

  /// No description provided for @cqCapacityHint.
  ///
  /// In pt, this message translates to:
  /// **'Usamos o tempo médio para estimar a espera. Se pular, valem {minutes} min por atendimento e sem limite de pessoas.'**
  String cqCapacityHint(int minutes);

  /// No description provided for @cqAppearanceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha uma cor'**
  String get cqAppearanceTitle;

  /// No description provided for @cqAppearanceHint.
  ///
  /// In pt, this message translates to:
  /// **'Ela aparece na página que o cliente vê. Opcional.'**
  String get cqAppearanceHint;

  /// No description provided for @cqScheduleTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quando a fila funciona?'**
  String get cqScheduleTitle;

  /// No description provided for @cqScheduleHint.
  ///
  /// In pt, this message translates to:
  /// **'Por padrão a fila fica sempre aberta. Você pode pausar ou fechar quando quiser.'**
  String get cqScheduleHint;

  /// No description provided for @cqReviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Revise e crie'**
  String get cqReviewTitle;

  /// No description provided for @cqReviewHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque em Editar para mudar qualquer item.'**
  String get cqReviewHint;

  /// No description provided for @cqEdit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get cqEdit;

  /// No description provided for @cqSummaryEntry.
  ///
  /// In pt, this message translates to:
  /// **'Entrada'**
  String get cqSummaryEntry;

  /// No description provided for @cqSummaryCapacity.
  ///
  /// In pt, this message translates to:
  /// **'Tempo e limite'**
  String get cqSummaryCapacity;

  /// No description provided for @cqSummarySchedule.
  ///
  /// In pt, this message translates to:
  /// **'Funcionamento'**
  String get cqSummarySchedule;

  /// No description provided for @cqAverageTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio: {time}'**
  String cqAverageTime(String time);

  /// No description provided for @cqWaitingLimit.
  ///
  /// In pt, this message translates to:
  /// **'Limite de espera: {limit}'**
  String cqWaitingLimit(String limit);

  /// No description provided for @cqLimitPeople.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 pessoa} other{{count} pessoas}}'**
  String cqLimitPeople(int count);

  /// No description provided for @cqAlwaysOpen.
  ///
  /// In pt, this message translates to:
  /// **'Sempre aberta'**
  String get cqAlwaysOpen;

  /// No description provided for @cqNoExpiry.
  ///
  /// In pt, this message translates to:
  /// **'Não expirar'**
  String get cqNoExpiry;

  /// No description provided for @cqDefaultColor.
  ///
  /// In pt, this message translates to:
  /// **'Padrão'**
  String get cqDefaultColor;

  /// No description provided for @cqGroupChosen.
  ///
  /// In pt, this message translates to:
  /// **'Em um grupo'**
  String get cqGroupChosen;

  /// No description provided for @cqSummaryName.
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get cqSummaryName;

  /// No description provided for @cqCreateTimeout.
  ///
  /// In pt, this message translates to:
  /// **'Sem resposta. A fila pode ter sido criada: confira sua lista antes de tentar de novo.'**
  String get cqCreateTimeout;

  /// No description provided for @cqResumeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Continuar de onde parou?'**
  String get cqResumeTitle;

  /// No description provided for @cqResumeBody.
  ///
  /// In pt, this message translates to:
  /// **'Você tem uma fila em andamento que não foi criada. Quer continuar de onde parou ou descartar?'**
  String get cqResumeBody;

  /// No description provided for @cqResume.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get cqResume;

  /// No description provided for @cqDiscardDraft.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get cqDiscardDraft;

  /// No description provided for @cqSaveDraft.
  ///
  /// In pt, this message translates to:
  /// **'Salvar rascunho'**
  String get cqSaveDraft;

  /// No description provided for @cqDraftDiscardBody.
  ///
  /// In pt, this message translates to:
  /// **'Você já preencheu campos. Salve como rascunho para continuar depois ou descarte o que digitou.'**
  String get cqDraftDiscardBody;

  /// No description provided for @cqCreatedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fila criada'**
  String get cqCreatedTitle;

  /// No description provided for @cqCreatedHint.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhe o link ou mostre o QR para as pessoas entrarem.'**
  String get cqCreatedHint;

  /// No description provided for @cqOpenPanel.
  ///
  /// In pt, this message translates to:
  /// **'Abrir painel'**
  String get cqOpenPanel;

  /// No description provided for @cqPolishTitle.
  ///
  /// In pt, this message translates to:
  /// **'Deixe sua fila mais bonita e completa'**
  String get cqPolishTitle;

  /// No description provided for @cqShortcutLogo.
  ///
  /// In pt, this message translates to:
  /// **'Logo e cor'**
  String get cqShortcutLogo;

  /// No description provided for @cqShortcutShortLink.
  ///
  /// In pt, this message translates to:
  /// **'Link curto'**
  String get cqShortcutShortLink;

  /// No description provided for @cqShortcutOperators.
  ///
  /// In pt, this message translates to:
  /// **'Operadores'**
  String get cqShortcutOperators;

  /// No description provided for @cqShortcutAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get cqShortcutAlerts;

  /// No description provided for @cqLimitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Limite de filas atingido'**
  String get cqLimitTitle;

  /// No description provided for @cqCheckingLimit.
  ///
  /// In pt, this message translates to:
  /// **'Verificando seu limite de filas'**
  String get cqCheckingLimit;

  /// No description provided for @cqShareLink.
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar link'**
  String get cqShareLink;

  /// No description provided for @cqAlertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Quer receber alertas desta fila?'**
  String get cqAlertsTitle;

  /// No description provided for @cqAlertsHint.
  ///
  /// In pt, this message translates to:
  /// **'Opcional. Avisamos você quando a espera, o não comparecimento ou a fila parada passarem do limite que escolher.'**
  String get cqAlertsHint;

  /// No description provided for @cqAlertsPushNote.
  ///
  /// In pt, this message translates to:
  /// **'Os avisos chegam por notificação. Se a conta recebe esses avisos é uma opção da tela Alertas operacionais, nas configurações da fila.'**
  String get cqAlertsPushNote;

  /// No description provided for @cqSummaryAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get cqSummaryAlerts;

  /// No description provided for @metricsScopeUngrouped.
  ///
  /// In pt, this message translates to:
  /// **'Filas sem grupo'**
  String get metricsScopeUngrouped;

  /// No description provided for @groupOverviewTitle.
  ///
  /// In pt, this message translates to:
  /// **'Por grupo'**
  String get groupOverviewTitle;

  /// No description provided for @groupOverviewHint.
  ///
  /// In pt, this message translates to:
  /// **'Toque num grupo para ver só as filas dele.'**
  String get groupOverviewHint;

  /// No description provided for @groupOverviewOpenHint.
  ///
  /// In pt, this message translates to:
  /// **'Ver só este grupo'**
  String get groupOverviewOpenHint;

  /// No description provided for @metricsGroupQueues.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 fila} other{{count} filas}}'**
  String metricsGroupQueues(int count);

  /// No description provided for @groupPartialData.
  ///
  /// In pt, this message translates to:
  /// **'dados parciais'**
  String get groupPartialData;

  /// No description provided for @cmpColQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila'**
  String get cmpColQueue;

  /// No description provided for @cmpColGroup.
  ///
  /// In pt, this message translates to:
  /// **'Grupo'**
  String get cmpColGroup;

  /// No description provided for @cmpColServed.
  ///
  /// In pt, this message translates to:
  /// **'Atend.'**
  String get cmpColServed;

  /// No description provided for @cmpColWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera'**
  String get cmpColWait;

  /// No description provided for @cmpColNoShow.
  ///
  /// In pt, this message translates to:
  /// **'Não comp.'**
  String get cmpColNoShow;

  /// No description provided for @cmpColRating.
  ///
  /// In pt, this message translates to:
  /// **'Nota'**
  String get cmpColRating;

  /// No description provided for @sortByHint.
  ///
  /// In pt, this message translates to:
  /// **'Ordenar por {column}'**
  String sortByHint(String column);

  /// No description provided for @sortAscending.
  ///
  /// In pt, this message translates to:
  /// **'ordem crescente'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In pt, this message translates to:
  /// **'ordem decrescente'**
  String get sortDescending;

  /// No description provided for @scopePickerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolher escopo'**
  String get scopePickerTitle;

  /// No description provided for @scopeSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar grupo ou fila'**
  String get scopeSearchHint;

  /// No description provided for @scopeNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nada encontrado'**
  String get scopeNoResults;

  /// No description provided for @csvGroup.
  ///
  /// In pt, this message translates to:
  /// **'grupo'**
  String get csvGroup;

  /// No description provided for @csvQueuesCount.
  ///
  /// In pt, this message translates to:
  /// **'filas'**
  String get csvQueuesCount;

  /// No description provided for @csvPartialData.
  ///
  /// In pt, this message translates to:
  /// **'dados parciais'**
  String get csvPartialData;

  /// No description provided for @csvYes.
  ///
  /// In pt, this message translates to:
  /// **'sim'**
  String get csvYes;

  /// No description provided for @csvNo.
  ///
  /// In pt, this message translates to:
  /// **'não'**
  String get csvNo;

  /// No description provided for @csvDeltaTotalPct.
  ///
  /// In pt, this message translates to:
  /// **'variação atendimentos (%)'**
  String get csvDeltaTotalPct;

  /// No description provided for @csvDeltaWaitPct.
  ///
  /// In pt, this message translates to:
  /// **'variação espera média (%)'**
  String get csvDeltaWaitPct;

  /// No description provided for @csvDeltaMedianPct.
  ///
  /// In pt, this message translates to:
  /// **'variação mediana (%)'**
  String get csvDeltaMedianPct;

  /// No description provided for @csvDeltaP90Pct.
  ///
  /// In pt, this message translates to:
  /// **'variação P90 (%)'**
  String get csvDeltaP90Pct;

  /// No description provided for @csvDeltaNoShowPoints.
  ///
  /// In pt, this message translates to:
  /// **'variação não comparecimento (p.p.)'**
  String get csvDeltaNoShowPoints;

  /// No description provided for @groupSectionQueues.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{{count} fila} other{{count} filas}}'**
  String groupSectionQueues(int count);

  /// No description provided for @groupSectionWaiting.
  ///
  /// In pt, this message translates to:
  /// **'{count} esperando'**
  String groupSectionWaiting(int count);

  /// No description provided for @groupSectionExpanded.
  ///
  /// In pt, this message translates to:
  /// **'expandido'**
  String get groupSectionExpanded;

  /// No description provided for @groupSectionCollapsed.
  ///
  /// In pt, this message translates to:
  /// **'recolhido'**
  String get groupSectionCollapsed;

  /// No description provided for @groupSectionSemantics.
  ///
  /// In pt, this message translates to:
  /// **'{name}, {queues}, {waiting}, {state}'**
  String groupSectionSemantics(
    String name,
    String queues,
    String waiting,
    String state,
  );

  /// No description provided for @groupChipSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Grupo: {name}'**
  String groupChipSemantics(String name);

  /// No description provided for @groupQueueCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Sem filas} =1{1 fila} other{{count} filas}}'**
  String groupQueueCount(int count);

  /// No description provided for @groupDeleteConfirmCount.
  ///
  /// In pt, this message translates to:
  /// **'Excluir o grupo \"{name}\"? {count, plural, =1{1 fila ficará sem grupo.} other{{count} filas ficarão sem grupo.}}'**
  String groupDeleteConfirmCount(String name, int count);

  /// No description provided for @groupBatchMenuLabel.
  ///
  /// In pt, this message translates to:
  /// **'Ações em lote do grupo {name}'**
  String groupBatchMenuLabel(String name);

  /// No description provided for @groupPauseAll.
  ///
  /// In pt, this message translates to:
  /// **'Pausar todas'**
  String get groupPauseAll;

  /// No description provided for @groupCloseAll.
  ///
  /// In pt, this message translates to:
  /// **'Fechar todas'**
  String get groupCloseAll;

  /// No description provided for @groupReopenAll.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir todas'**
  String get groupReopenAll;

  /// No description provided for @groupBatchConfirmPause.
  ///
  /// In pt, this message translates to:
  /// **'Pausar {count, plural, =1{1 fila} other{{count} filas}} do grupo \"{name}\"?'**
  String groupBatchConfirmPause(int count, String name);

  /// No description provided for @groupBatchConfirmClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar {count, plural, =1{1 fila} other{{count} filas}} do grupo \"{name}\"?'**
  String groupBatchConfirmClose(int count, String name);

  /// No description provided for @groupBatchConfirmReopen.
  ///
  /// In pt, this message translates to:
  /// **'Reabrir {count, plural, =1{1 fila} other{{count} filas}} do grupo \"{name}\"?'**
  String groupBatchConfirmReopen(int count, String name);

  /// No description provided for @groupBatchDone.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 fila atualizada} other{{count} filas atualizadas}}'**
  String groupBatchDone(int count);

  /// No description provided for @groupBatchPartial.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total} atualizadas. Tente de novo para as demais.'**
  String groupBatchPartial(int done, int total);

  /// No description provided for @groupBatchEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila do grupo para atualizar.'**
  String get groupBatchEmpty;

  /// No description provided for @groupReorderHandle.
  ///
  /// In pt, this message translates to:
  /// **'Arrastar para reordenar o grupo \"{name}\"'**
  String groupReorderHandle(String name);

  /// No description provided for @groupMoveUp.
  ///
  /// In pt, this message translates to:
  /// **'Mover para cima'**
  String get groupMoveUp;

  /// No description provided for @groupMoveDown.
  ///
  /// In pt, this message translates to:
  /// **'Mover para baixo'**
  String get groupMoveDown;

  /// No description provided for @groupMoved.
  ///
  /// In pt, this message translates to:
  /// **'Grupo \"{name}\" na posição {position}'**
  String groupMoved(String name, int position);

  /// No description provided for @groupColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor do grupo'**
  String get groupColor;

  /// No description provided for @groupColorOf.
  ///
  /// In pt, this message translates to:
  /// **'Cor do grupo \"{name}\"'**
  String groupColorOf(String name);

  /// No description provided for @groupColorNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem cor'**
  String get groupColorNone;

  /// No description provided for @queueSelect.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar filas'**
  String get queueSelect;

  /// No description provided for @selectionExit.
  ///
  /// In pt, this message translates to:
  /// **'Sair da seleção'**
  String get selectionExit;

  /// No description provided for @selectionCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma fila selecionada} =1{1 fila selecionada} other{{count} filas selecionadas}}'**
  String selectionCount(int count);

  /// No description provided for @queueSelectLabel.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar a fila {name}'**
  String queueSelectLabel(String name);

  /// No description provided for @moveToGroup.
  ///
  /// In pt, this message translates to:
  /// **'Mover para grupo…'**
  String get moveToGroup;

  /// No description provided for @moveToGroupTitle.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Mover 1 fila para} other{Mover {count} filas para}}'**
  String moveToGroupTitle(int count);

  /// No description provided for @moveGroupDone.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{1 fila movida} other{{count} filas movidas}} para \"{group}\"'**
  String moveGroupDone(int count, String group);

  /// No description provided for @moveGroupPartial.
  ///
  /// In pt, this message translates to:
  /// **'{done} de {total} filas movidas. Tente de novo para as demais.'**
  String moveGroupPartial(int done, int total);

  /// No description provided for @moveGroupEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma das filas selecionadas pôde ser movida.'**
  String get moveGroupEmpty;

  /// No description provided for @groupApplyAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar alertas a todas as filas'**
  String get groupApplyAlerts;

  /// No description provided for @groupAlertsDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas do grupo \"{name}\"'**
  String groupAlertsDialogTitle(String name);

  /// No description provided for @groupAlertsDialogHint.
  ///
  /// In pt, this message translates to:
  /// **'Esta configuração será copiada para todas as filas do grupo, no lugar da atual.'**
  String get groupAlertsDialogHint;

  /// No description provided for @groupAlertsContinue.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get groupAlertsContinue;

  /// No description provided for @groupAlertsConfirm.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar esta configuração de alertas a {count, plural, =1{1 fila} other{{count} filas}} do grupo \"{name}\"? Os alertas atuais dessas filas serão substituídos.'**
  String groupAlertsConfirm(int count, String name);

  /// No description provided for @groupAlertsApply.
  ///
  /// In pt, this message translates to:
  /// **'Aplicar'**
  String get groupAlertsApply;

  /// No description provided for @groupAlertsDone.
  ///
  /// In pt, this message translates to:
  /// **'Alertas aplicados a {count, plural, =1{1 fila} other{{count} filas}}'**
  String groupAlertsDone(int count);

  /// No description provided for @groupHistoryTitle.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do grupo'**
  String get groupHistoryTitle;

  /// No description provided for @groupHistoryOpen.
  ///
  /// In pt, this message translates to:
  /// **'Histórico do grupo'**
  String get groupHistoryOpen;

  /// No description provided for @groupHistoryNoQueues.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila neste grupo'**
  String get groupHistoryNoQueues;

  /// No description provided for @groupHistoryNoQueuesHint.
  ///
  /// In pt, this message translates to:
  /// **'Coloque filas no grupo para ver o histórico consolidado.'**
  String get groupHistoryNoQueuesHint;

  /// No description provided for @groupHistoryTruncated.
  ///
  /// In pt, this message translates to:
  /// **'Mostrando só os {limit} registros mais recentes de cada fila. Filas com histórico cortado: {queues}.'**
  String groupHistoryTruncated(int limit, String queues);

  /// No description provided for @groupHistoryShowMore.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar mais ({shown} de {total})'**
  String groupHistoryShowMore(int shown, int total);

  /// No description provided for @historyQueueOrigin.
  ///
  /// In pt, this message translates to:
  /// **'Fila: {name}'**
  String historyQueueOrigin(String name);

  /// No description provided for @colQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila'**
  String get colQueue;

  /// No description provided for @infoButtonSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Explicação do indicador: {name}'**
  String infoButtonSemantics(String name);

  /// No description provided for @infoWhat.
  ///
  /// In pt, this message translates to:
  /// **'O que é'**
  String get infoWhat;

  /// No description provided for @infoHow.
  ///
  /// In pt, this message translates to:
  /// **'Como é calculado'**
  String get infoHow;

  /// No description provided for @infoData.
  ///
  /// In pt, this message translates to:
  /// **'Dados usados'**
  String get infoData;

  /// No description provided for @infoUse.
  ///
  /// In pt, this message translates to:
  /// **'Para que serve'**
  String get infoUse;

  /// No description provided for @infoClose.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get infoClose;

  /// No description provided for @attColService.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio'**
  String get attColService;

  /// No description provided for @attColDeviation.
  ///
  /// In pt, this message translates to:
  /// **'Desvio'**
  String get attColDeviation;

  /// No description provided for @attColRate.
  ///
  /// In pt, this message translates to:
  /// **'Atend./h'**
  String get attColRate;

  /// No description provided for @attColIdle.
  ///
  /// In pt, this message translates to:
  /// **'Ocioso'**
  String get attColIdle;

  /// No description provided for @attInsufficientNote.
  ///
  /// In pt, this message translates to:
  /// **'— indica amostra insuficiente (menos de {samples} atendimentos ou janela curta).'**
  String attInsufficientNote(int samples);

  /// No description provided for @attRowSpoken.
  ///
  /// In pt, this message translates to:
  /// **'{name}. {served} atendimentos, tempo médio {service}, desvio {deviation}, {rate} atendimentos por hora, ociosidade {idle}, {noShow} não compareceram, nota {rating}'**
  String attRowSpoken(
    String name,
    int served,
    String service,
    String deviation,
    String rate,
    String idle,
    int noShow,
    String rating,
  );

  /// No description provided for @attChartTitleHour.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos por hora do dia'**
  String get attChartTitleHour;

  /// No description provided for @attChartTitleShift.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos por turno'**
  String get attChartTitleShift;

  /// No description provided for @attChartModeHour.
  ///
  /// In pt, this message translates to:
  /// **'Hora'**
  String get attChartModeHour;

  /// No description provided for @attChartModeShift.
  ///
  /// In pt, this message translates to:
  /// **'Turno'**
  String get attChartModeShift;

  /// No description provided for @attChartOperatorLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atendente do gráfico'**
  String get attChartOperatorLabel;

  /// No description provided for @attChartAll.
  ///
  /// In pt, this message translates to:
  /// **'Todos os atendentes'**
  String get attChartAll;

  /// No description provided for @attChartEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Sem atendimentos concluídos para este gráfico.'**
  String get attChartEmpty;

  /// No description provided for @attChartPeak.
  ///
  /// In pt, this message translates to:
  /// **'Mais atendimentos: {label} ({count})'**
  String attChartPeak(String label, int count);

  /// No description provided for @attChartSemantics.
  ///
  /// In pt, this message translates to:
  /// **'Gráfico de atendimentos. {summary}'**
  String attChartSemantics(String summary);

  /// No description provided for @attShiftMorning.
  ///
  /// In pt, this message translates to:
  /// **'Manhã (6h–12h)'**
  String get attShiftMorning;

  /// No description provided for @attShiftAfternoon.
  ///
  /// In pt, this message translates to:
  /// **'Tarde (12h–18h)'**
  String get attShiftAfternoon;

  /// No description provided for @attShiftNight.
  ///
  /// In pt, this message translates to:
  /// **'Noite (18h–6h)'**
  String get attShiftNight;

  /// No description provided for @csvDeviationPct.
  ///
  /// In pt, this message translates to:
  /// **'desvio vs média (%)'**
  String get csvDeviationPct;

  /// No description provided for @csvRatePerHour.
  ///
  /// In pt, this message translates to:
  /// **'atendimentos por hora (janela de atuação)'**
  String get csvRatePerHour;

  /// No description provided for @csvIdlePct.
  ///
  /// In pt, this message translates to:
  /// **'ociosidade (%)'**
  String get csvIdlePct;

  /// No description provided for @abandonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desistências'**
  String get abandonTitle;

  /// No description provided for @abandonSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quem entrou e saiu antes de ser atendido. Remoções automáticas (expiração e fechamento) não contam.'**
  String get abandonSubtitle;

  /// No description provided for @abandonBand.
  ///
  /// In pt, this message translates to:
  /// **'{start}–{end} min'**
  String abandonBand(int start, int end);

  /// No description provided for @abandonBandOpen.
  ///
  /// In pt, this message translates to:
  /// **'{start}+ min'**
  String abandonBandOpen(int start);

  /// No description provided for @abandonWaitTitle.
  ///
  /// In pt, this message translates to:
  /// **'Taxa por faixa de espera'**
  String get abandonWaitTitle;

  /// No description provided for @abandonWaitHint.
  ///
  /// In pt, this message translates to:
  /// **'Desistências a cada 10 min de espera, entre quem chegou a cada faixa.'**
  String get abandonWaitHint;

  /// No description provided for @abandonWaitEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Amostra insuficiente: cada faixa precisa de pelo menos {min} pessoas para mostrar a taxa.'**
  String abandonWaitEmpty(int min);

  /// No description provided for @abandonBarSpoken.
  ///
  /// In pt, this message translates to:
  /// **'{band}: {pct}% a cada 10 min'**
  String abandonBarSpoken(String band, int pct);

  /// No description provided for @abandonBarNoData.
  ///
  /// In pt, this message translates to:
  /// **'{band}: dados insuficientes'**
  String abandonBarNoData(String band);

  /// No description provided for @abandonInflectionFound.
  ///
  /// In pt, this message translates to:
  /// **'Ponto de inflexão: a partir de {band} a desistência passa de {limit}% a cada 10 min.'**
  String abandonInflectionFound(String band, int limit);

  /// No description provided for @abandonInflectionNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma faixa passa do limite de {limit}% a cada 10 min.'**
  String abandonInflectionNone(int limit);

  /// No description provided for @abandonEstimateTitle.
  ///
  /// In pt, this message translates to:
  /// **'Taxa por estimativa mostrada'**
  String get abandonEstimateTitle;

  /// No description provided for @abandonEstimateHint.
  ///
  /// In pt, this message translates to:
  /// **'Percentual de desistência conforme a estimativa que o cliente viu ao entrar.'**
  String get abandonEstimateHint;

  /// No description provided for @abandonEstimateEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há registros com a estimativa mostrada na entrada. O histórico anterior à atualização que grava a estimativa não tem esse dado.'**
  String get abandonEstimateEmpty;

  /// No description provided for @abandonEstimateBarSpoken.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa {band}: {pct}% desistiram'**
  String abandonEstimateBarSpoken(String band, int pct);

  /// No description provided for @abandonEstimateBarNoData.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa {band}: dados insuficientes'**
  String abandonEstimateBarNoData(String band);

  /// No description provided for @estimateAccuracyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Precisão da estimativa'**
  String get estimateAccuracyTitle;

  /// No description provided for @estimateAccuracyMean.
  ///
  /// In pt, this message translates to:
  /// **'Espera real menos estimativa: {value} min em média ({samples} atendimentos)'**
  String estimateAccuracyMean(String value, int samples);

  /// No description provided for @estimateAccuracyAbs.
  ///
  /// In pt, this message translates to:
  /// **'Erro absoluto médio: {value} min'**
  String estimateAccuracyAbs(String value);

  /// No description provided for @estimateAccuracyHint.
  ///
  /// In pt, this message translates to:
  /// **'Positivo: a espera foi maior que o prometido.'**
  String get estimateAccuracyHint;

  /// No description provided for @estimateAccuracyNone.
  ///
  /// In pt, this message translates to:
  /// **'Amostra insuficiente: são necessários {min} atendimentos com estimativa gravada.'**
  String estimateAccuracyNone(int min);

  /// No description provided for @abandonHourTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desistência por hora de chegada'**
  String get abandonHourTitle;

  /// No description provided for @abandonHourRateLabel.
  ///
  /// In pt, this message translates to:
  /// **'Taxa'**
  String get abandonHourRateLabel;

  /// No description provided for @abandonHourCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desistentes'**
  String get abandonHourCountLabel;

  /// No description provided for @abandonHourEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Amostra insuficiente: cada hora precisa de pelo menos {min} pessoas para mostrar a taxa.'**
  String abandonHourEmpty(int min);

  /// No description provided for @abandonHourPeak.
  ///
  /// In pt, this message translates to:
  /// **'Maior taxa às {hour}: {pct}% ({left} de {total})'**
  String abandonHourPeak(String hour, int pct, int left, int total);

  /// No description provided for @abandonHourSpoken.
  ///
  /// In pt, this message translates to:
  /// **'{hour}: {pct}% desistiram ({left} de {total})'**
  String abandonHourSpoken(String hour, int pct, int left, int total);

  /// No description provided for @abandonHourNoRate.
  ///
  /// In pt, this message translates to:
  /// **'{hour}: {left} de {total}, taxa com dados insuficientes'**
  String abandonHourNoRate(String hour, int left, int total);

  /// No description provided for @capacityCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Possível falta de capacidade'**
  String get capacityCardTitle;

  /// No description provided for @capacityCardBody.
  ///
  /// In pt, this message translates to:
  /// **'Nestes horários a espera média é de {wait} min ou mais e {rate}% ou mais desistem: {hours}. Considere reforçar o atendimento.'**
  String capacityCardBody(String hours, int wait, int rate);

  /// No description provided for @capacityCardNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum horário crítico no período'**
  String get capacityCardNone;

  /// No description provided for @csvWaitBand.
  ///
  /// In pt, this message translates to:
  /// **'faixa de espera (min)'**
  String get csvWaitBand;

  /// No description provided for @csvEstimateBand.
  ///
  /// In pt, this message translates to:
  /// **'faixa de estimativa (min)'**
  String get csvEstimateBand;

  /// No description provided for @csvAtRisk.
  ///
  /// In pt, this message translates to:
  /// **'chegaram à faixa'**
  String get csvAtRisk;

  /// No description provided for @csvAbandonRatePct.
  ///
  /// In pt, this message translates to:
  /// **'desistência (%)'**
  String get csvAbandonRatePct;

  /// No description provided for @csvAbandonPer10Pct.
  ///
  /// In pt, this message translates to:
  /// **'desistência por 10 min (%)'**
  String get csvAbandonPer10Pct;

  /// No description provided for @csvInflection.
  ///
  /// In pt, this message translates to:
  /// **'ponto de inflexão'**
  String get csvInflection;

  /// No description provided for @csvCapacityHours.
  ///
  /// In pt, this message translates to:
  /// **'horas com sinal de capacidade'**
  String get csvCapacityHours;

  /// No description provided for @csvEstimateErrorMin.
  ///
  /// In pt, this message translates to:
  /// **'erro médio da estimativa (min)'**
  String get csvEstimateErrorMin;

  /// No description provided for @csvEstimateAbsErrorMin.
  ///
  /// In pt, this message translates to:
  /// **'erro absoluto médio da estimativa (min)'**
  String get csvEstimateAbsErrorMin;

  /// No description provided for @biNameAttendantThroughput.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos por hora e turno'**
  String get biNameAttendantThroughput;

  /// No description provided for @biWhatAttendantThroughput.
  ///
  /// In pt, this message translates to:
  /// **'Quantos atendimentos cada atendente concluiu, distribuídos por hora do dia (0 a 23) e por turno (manhã 6h–12h, tarde 12h–18h, noite 18h–6h).'**
  String get biWhatAttendantThroughput;

  /// No description provided for @biHowAttendantThroughput.
  ///
  /// In pt, this message translates to:
  /// **'Conta os atendidos agrupados pelo instante em que terminaram (ou foram chamados, se faltar o término), convertido para o horário de São Paulo. Não compareceu e desistência não contam.'**
  String get biHowAttendantThroughput;

  /// No description provided for @biDataAttendantThroughput.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de término, horário da chamada e quem chamou.'**
  String get biDataAttendantThroughput;

  /// No description provided for @biUseAttendantThroughput.
  ///
  /// In pt, this message translates to:
  /// **'Ver em que horários e turnos cada pessoa concentra o trabalho e dimensionar a escala.'**
  String get biUseAttendantThroughput;

  /// No description provided for @biNameAttendantService.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio de serviço'**
  String get biNameAttendantService;

  /// No description provided for @biWhatAttendantService.
  ///
  /// In pt, this message translates to:
  /// **'Quanto tempo, em média, o atendente leva entre chamar o cliente e finalizar o atendimento.'**
  String get biWhatAttendantService;

  /// No description provided for @biHowAttendantService.
  ///
  /// In pt, this message translates to:
  /// **'Média de (término − chamada) dos atendidos. Com menos de {min} amostras válidas o valor não é mostrado (—).'**
  String biHowAttendantService(int min);

  /// No description provided for @biDataAttendantService.
  ///
  /// In pt, this message translates to:
  /// **'Horário da chamada, horário de término e resultado “atendido”.'**
  String get biDataAttendantService;

  /// No description provided for @biUseAttendantService.
  ///
  /// In pt, this message translates to:
  /// **'Conhecer o ritmo real de cada pessoa e ajustar o tempo médio configurado na fila.'**
  String get biUseAttendantService;

  /// No description provided for @biNameAttendantDeviation.
  ///
  /// In pt, this message translates to:
  /// **'Desvio contra a média'**
  String get biNameAttendantDeviation;

  /// No description provided for @biWhatAttendantDeviation.
  ///
  /// In pt, this message translates to:
  /// **'Quanto o tempo médio do atendente se afasta da média de todos no escopo selecionado. Negativo significa mais rápido.'**
  String get biWhatAttendantDeviation;

  /// No description provided for @biHowAttendantDeviation.
  ///
  /// In pt, this message translates to:
  /// **'(média do atendente − média do escopo) ÷ média do escopo × 100. A média do escopo é ponderada pelas amostras. Só entram atendentes com pelo menos {min} amostras; os demais mostram —.'**
  String biHowAttendantDeviation(int min);

  /// No description provided for @biDataAttendantDeviation.
  ///
  /// In pt, this message translates to:
  /// **'Tempo de serviço dos atendidos de cada atendente.'**
  String get biDataAttendantDeviation;

  /// No description provided for @biUseAttendantDeviation.
  ///
  /// In pt, this message translates to:
  /// **'Identificar quem destoa do padrão, para treino ou revisão do tempo médio. Não mede qualidade: um atendimento mais longo pode ser mais complexo.'**
  String get biUseAttendantDeviation;

  /// No description provided for @biNameAttendantRate.
  ///
  /// In pt, this message translates to:
  /// **'Atendimentos por hora na janela de atuação'**
  String get biNameAttendantRate;

  /// No description provided for @biWhatAttendantRate.
  ///
  /// In pt, this message translates to:
  /// **'O ritmo do atendente dentro da janela em que atuou no dia. Pausas e intervalos entre atendimentos entram na janela; não é hora efetivamente trabalhada.'**
  String get biWhatAttendantRate;

  /// No description provided for @biHowAttendantRate.
  ///
  /// In pt, this message translates to:
  /// **'Por dia: atendidos ÷ horas entre a primeira chamada e o último término. O dia só vale com {min} ou mais atendimentos e janela de pelo menos {window} min. O valor mostrado soma atendimentos e horas dos dias válidos.'**
  String biHowAttendantRate(int min, int window);

  /// No description provided for @biDataAttendantRate.
  ///
  /// In pt, this message translates to:
  /// **'Horário da chamada, horário de término, resultado e quem chamou.'**
  String get biDataAttendantRate;

  /// No description provided for @biUseAttendantRate.
  ///
  /// In pt, this message translates to:
  /// **'Comparar produtividade sem o viés de quem trabalhou poucas horas.'**
  String get biUseAttendantRate;

  /// No description provided for @biNameAttendantIdle.
  ///
  /// In pt, this message translates to:
  /// **'Ociosidade'**
  String get biNameAttendantIdle;

  /// No description provided for @biWhatAttendantIdle.
  ///
  /// In pt, this message translates to:
  /// **'Parcela do tempo em que o atendente ficou parado havendo gente esperando.'**
  String get biWhatAttendantIdle;

  /// No description provided for @biHowAttendantIdle.
  ///
  /// In pt, this message translates to:
  /// **'Soma dos intervalos entre o fim de um atendimento e a chamada do próximo, ÷ tempo observado no dia. O intervalo só conta se o próximo cliente já estava na fila, se for maior que zero e menor ou igual a {cap} min (acima disso presume-se pausa) e se ocorrer no mesmo dia. Só aparece com pelo menos {min} atendimentos concluídos.'**
  String biHowAttendantIdle(int cap, int min);

  /// No description provided for @biDataAttendantIdle.
  ///
  /// In pt, this message translates to:
  /// **'Horário de entrada na fila, da chamada e do término. É uma aproximação: o histórico não guarda o tamanho da fila em cada instante.'**
  String get biDataAttendantIdle;

  /// No description provided for @biUseAttendantIdle.
  ///
  /// In pt, this message translates to:
  /// **'Achar tempo perdido entre atendimentos (troca lenta, distração) separando-o de fila vazia.'**
  String get biUseAttendantIdle;

  /// No description provided for @biNameAbandonWait.
  ///
  /// In pt, this message translates to:
  /// **'Desistência por faixa de espera'**
  String get biNameAbandonWait;

  /// No description provided for @biWhatAbandonWait.
  ///
  /// In pt, this message translates to:
  /// **'De quem esperou pelo menos até certo ponto, a fração que desistiu naquela faixa.'**
  String get biWhatAbandonWait;

  /// No description provided for @biHowAbandonWait.
  ///
  /// In pt, this message translates to:
  /// **'Faixas de {bands} min. Em cada faixa: pessoas que desistiram na faixa ÷ pessoas que chegaram a ela (inclusive quem esperou mais e foi atendido). As barras mostram a taxa a cada 10 min (limitada a 100%; faixas mais estreitas que 5 min usam 5 min no divisor), para comparar faixas de larguras diferentes. Faixa com menos de {min} pessoas não mostra taxa.'**
  String biHowAbandonWait(String bands, int min);

  /// No description provided for @biDataAbandonWait.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de entrada, chamada e término, e motivo de saída. Remoções do sistema (expirada ou fechada) ficam de fora. Quem ainda está na fila não aparece, então esperas longas recentes podem estar sub-representadas.'**
  String get biDataAbandonWait;

  /// No description provided for @biUseAbandonWait.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar a partir de que espera o cliente começa a ir embora.'**
  String get biUseAbandonWait;

  /// No description provided for @biNameAbandonInflection.
  ///
  /// In pt, this message translates to:
  /// **'Ponto de inflexão'**
  String get biNameAbandonInflection;

  /// No description provided for @biWhatAbandonInflection.
  ///
  /// In pt, this message translates to:
  /// **'A primeira faixa de espera em que a desistência passa do tolerável.'**
  String get biWhatAbandonInflection;

  /// No description provided for @biHowAbandonInflection.
  ///
  /// In pt, this message translates to:
  /// **'Primeira faixa, em ordem crescente, com mais de {limit}% de desistência a cada 10 minutos. Faixas sem taxa (amostra insuficiente) são puladas. Se nenhuma passar, não há ponto de inflexão.'**
  String biHowAbandonInflection(int limit);

  /// No description provided for @biDataAbandonInflection.
  ///
  /// In pt, this message translates to:
  /// **'A mesma taxa por faixa de espera.'**
  String get biDataAbandonInflection;

  /// No description provided for @biUseAbandonInflection.
  ///
  /// In pt, this message translates to:
  /// **'Definir a meta de espera máxima e o texto de aviso ao cliente.'**
  String get biUseAbandonInflection;

  /// No description provided for @biNameAbandonEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Desistência por estimativa mostrada'**
  String get biNameAbandonEstimate;

  /// No description provided for @biWhatAbandonEstimate.
  ///
  /// In pt, this message translates to:
  /// **'A taxa de desistência separada pela estimativa de espera que o cliente viu ao entrar na fila.'**
  String get biWhatAbandonEstimate;

  /// No description provided for @biHowAbandonEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Agrupa por estimativa ({bands} min): desistentes ÷ total de pessoas que viram aquela estimativa. Faixa com menos de {min} pessoas não mostra taxa.'**
  String biHowAbandonEstimate(String bands, int min);

  /// No description provided for @biDataAbandonEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa gravada na entrada e resultado. Registros anteriores à atualização que grava a estimativa não têm o campo e ficam de fora.'**
  String get biDataAbandonEstimate;

  /// No description provided for @biUseAbandonEstimate.
  ///
  /// In pt, this message translates to:
  /// **'Saber se prometer uma espera longa afasta clientes, e se vale mostrar a estimativa de outra forma.'**
  String get biUseAbandonEstimate;

  /// No description provided for @biNameEstimateAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Precisão da estimativa'**
  String get biNameEstimateAccuracy;

  /// No description provided for @biWhatEstimateAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'O quanto a estimativa mostrada ao cliente errou, em minutos.'**
  String get biWhatEstimateAccuracy;

  /// No description provided for @biHowEstimateAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Média de (espera real − estimativa) para atendidos e não compareceu. Positivo: a espera foi maior que o prometido. Também mostra o erro absoluto médio, que não deixa erros positivos e negativos se anularem. Menos de {min} amostras: não calcula.'**
  String biHowEstimateAccuracy(int min);

  /// No description provided for @biDataEstimateAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Estimativa gravada na entrada, horário de entrada e de chamada. Registros anteriores à gravação da estimativa ficam de fora.'**
  String get biDataEstimateAccuracy;

  /// No description provided for @biUseEstimateAccuracy.
  ///
  /// In pt, this message translates to:
  /// **'Avaliar se o tempo médio configurado reflete a realidade e quando ajustá-lo.'**
  String get biUseEstimateAccuracy;

  /// No description provided for @biNameAbandonHour.
  ///
  /// In pt, this message translates to:
  /// **'Desistência por hora de chegada'**
  String get biNameAbandonHour;

  /// No description provided for @biWhatAbandonHour.
  ///
  /// In pt, this message translates to:
  /// **'A taxa e a quantidade de desistências conforme a hora em que a pessoa entrou na fila.'**
  String get biWhatAbandonHour;

  /// No description provided for @biHowAbandonHour.
  ///
  /// In pt, this message translates to:
  /// **'Agrupa pela hora de entrada (São Paulo). Taxa = desistentes ÷ (atendidos + não compareceu + desistentes). Hora com menos de {min} pessoas não mostra taxa, mas a contagem aparece.'**
  String biHowAbandonHour(int min);

  /// No description provided for @biDataAbandonHour.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de entrada, espera e motivo de saída. Remoções do sistema ficam de fora.'**
  String get biDataAbandonHour;

  /// No description provided for @biUseAbandonHour.
  ///
  /// In pt, this message translates to:
  /// **'Localizar os horários de pico problemáticos.'**
  String get biUseAbandonHour;

  /// No description provided for @biNameCapacitySignal.
  ///
  /// In pt, this message translates to:
  /// **'Sinal de capacidade'**
  String get biNameCapacitySignal;

  /// No description provided for @biWhatCapacitySignal.
  ///
  /// In pt, this message translates to:
  /// **'As horas em que a fila parece subdimensionada.'**
  String get biWhatCapacitySignal;

  /// No description provided for @biHowCapacitySignal.
  ///
  /// In pt, this message translates to:
  /// **'Horas com espera média de {wait} min ou mais e taxa de desistência de {rate}% ou mais. Horas sem taxa (amostra insuficiente) não entram.'**
  String biHowCapacitySignal(int wait, int rate);

  /// No description provided for @biDataCapacitySignal.
  ///
  /// In pt, this message translates to:
  /// **'A desistência por hora de chegada e a espera média de cada hora.'**
  String get biDataCapacitySignal;

  /// No description provided for @biUseCapacitySignal.
  ///
  /// In pt, this message translates to:
  /// **'Indicar onde reforçar atendentes ou ajustar horários.'**
  String get biUseCapacitySignal;

  /// No description provided for @abandonBarCounts.
  ///
  /// In pt, this message translates to:
  /// **'{left} de {total} desistiram'**
  String abandonBarCounts(int left, int total);

  /// No description provided for @abandonScopeQueue.
  ///
  /// In pt, this message translates to:
  /// **'Fila: {name} (filtro da seção Por atendente)'**
  String abandonScopeQueue(String name);

  /// No description provided for @goalsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas de atendimento'**
  String get goalsTitle;

  /// No description provided for @goalsNone.
  ///
  /// In pt, this message translates to:
  /// **'Sem metas definidas'**
  String get goalsNone;

  /// No description provided for @goalsValueWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera até {min} min'**
  String goalsValueWait(int min);

  /// No description provided for @goalsValueService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento até {min} min'**
  String goalsValueService(int min);

  /// No description provided for @goalsValueTarget.
  ///
  /// In pt, this message translates to:
  /// **'alvo {pct}%'**
  String goalsValueTarget(int pct);

  /// No description provided for @goalsDialogHint.
  ///
  /// In pt, this message translates to:
  /// **'Defina o tempo aceitável e a parte dos atendimentos que deve cumprir a meta. Deixe em branco o que não quiser medir.'**
  String get goalsDialogHint;

  /// No description provided for @goalsWaitLabel.
  ///
  /// In pt, this message translates to:
  /// **'Espera máxima (min)'**
  String get goalsWaitLabel;

  /// No description provided for @goalsServiceLabel.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento máximo (min)'**
  String get goalsServiceLabel;

  /// No description provided for @goalsTargetLabel.
  ///
  /// In pt, this message translates to:
  /// **'Alvo de cumprimento (%)'**
  String get goalsTargetLabel;

  /// No description provided for @goalsTargetHint.
  ///
  /// In pt, this message translates to:
  /// **'Padrão {pct}'**
  String goalsTargetHint(int pct);

  /// No description provided for @goalsErrRange.
  ///
  /// In pt, this message translates to:
  /// **'Informe de {min} a {max} minutos.'**
  String goalsErrRange(int min, int max);

  /// No description provided for @goalsErrTarget.
  ///
  /// In pt, this message translates to:
  /// **'Informe de {min} a {max}%.'**
  String goalsErrTarget(int min, int max);

  /// No description provided for @goalsErrNone.
  ///
  /// In pt, this message translates to:
  /// **'Defina pelo menos uma meta: espera ou atendimento.'**
  String get goalsErrNone;

  /// No description provided for @goalsRemove.
  ///
  /// In pt, this message translates to:
  /// **'Remover metas'**
  String get goalsRemove;

  /// No description provided for @goalRiskTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meta de espera em risco'**
  String get goalRiskTitle;

  /// No description provided for @goalRiskBody.
  ///
  /// In pt, this message translates to:
  /// **'Com {waiting} na fila, a espera estimada é de {est} min, acima da meta de {goal} min.'**
  String goalRiskBody(int waiting, int est, int goal);

  /// No description provided for @goalRiskAction.
  ///
  /// In pt, this message translates to:
  /// **'Sugestão: chame mais um atendente ou abra outro balcão.'**
  String get goalRiskAction;

  /// No description provided for @goalsSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Metas'**
  String get goalsSectionTitle;

  /// No description provided for @goalsSectionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Cumprimento das metas definidas em cada fila, no período e escopo escolhidos.'**
  String get goalsSectionSubtitle;

  /// No description provided for @goalsQueuesCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Meta de 1 fila no escopo} other{Metas de {count} filas no escopo}}'**
  String goalsQueuesCount(int count);

  /// No description provided for @goalsWaitCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Espera dentro da meta'**
  String get goalsWaitCardTitle;

  /// No description provided for @goalsServiceCardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento dentro da meta'**
  String get goalsServiceCardTitle;

  /// No description provided for @goalsTargetLine.
  ///
  /// In pt, this message translates to:
  /// **'Alvo: {pct}% dentro do limite'**
  String goalsTargetLine(int pct);

  /// No description provided for @goalsCounts.
  ///
  /// In pt, this message translates to:
  /// **'{ok} de {total} dentro do limite'**
  String goalsCounts(int ok, int total);

  /// No description provided for @goalsMet.
  ///
  /// In pt, this message translates to:
  /// **'Atingida'**
  String get goalsMet;

  /// No description provided for @goalsNotMet.
  ///
  /// In pt, this message translates to:
  /// **'Não atingida'**
  String get goalsNotMet;

  /// No description provided for @goalsSmallSample.
  ///
  /// In pt, this message translates to:
  /// **'Amostra pequena: menos de {min} atendimentos avaliados.'**
  String goalsSmallSample(int min);

  /// No description provided for @goalsNoSamples.
  ///
  /// In pt, this message translates to:
  /// **'Sem atendimentos no período para avaliar esta meta.'**
  String get goalsNoSamples;

  /// No description provided for @goalsNotSet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila do escopo tem esta meta.'**
  String get goalsNotSet;

  /// No description provided for @goalsDailyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cumprimento por dia'**
  String get goalsDailyTitle;

  /// No description provided for @goalsDailySemantics.
  ///
  /// In pt, this message translates to:
  /// **'{days} dias avaliados, {missed} abaixo do alvo'**
  String goalsDailySemantics(int days, int missed);

  /// No description provided for @goalsMissedTitle.
  ///
  /// In pt, this message translates to:
  /// **'Períodos em que a meta não foi atingida'**
  String get goalsMissedTitle;

  /// No description provided for @goalsMissedNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum dia ou hora abaixo do alvo com pelo menos {min} avaliados.'**
  String goalsMissedNone(int min);

  /// No description provided for @goalsKindWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera'**
  String get goalsKindWait;

  /// No description provided for @goalsKindService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento'**
  String get goalsKindService;

  /// No description provided for @goalsMissedDayRow.
  ///
  /// In pt, this message translates to:
  /// **'{kind}, {day}: {pct}% ({ok} de {total}), alvo {target}%'**
  String goalsMissedDayRow(
    String kind,
    String day,
    int pct,
    int ok,
    int total,
    int target,
  );

  /// No description provided for @goalsMissedHoursRow.
  ///
  /// In pt, this message translates to:
  /// **'{kind}, horas abaixo do alvo: {hours}'**
  String goalsMissedHoursRow(String kind, String hours);

  /// No description provided for @goalsMissedMore.
  ///
  /// In pt, this message translates to:
  /// **'e mais {count} dias'**
  String goalsMissedMore(int count);

  /// No description provided for @goalsWorstWait.
  ///
  /// In pt, this message translates to:
  /// **'Maior violação de espera: {over} min acima da meta, em {day}.'**
  String goalsWorstWait(int over, String day);

  /// No description provided for @goalsWorstService.
  ///
  /// In pt, this message translates to:
  /// **'Maior violação de atendimento: {over} min acima da meta, em {day}.'**
  String goalsWorstService(int over, String day);

  /// No description provided for @goalsNoViolation.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma violação no período.'**
  String get goalsNoViolation;

  /// No description provided for @goalsCtaTitle.
  ///
  /// In pt, this message translates to:
  /// **'Defina metas de atendimento'**
  String get goalsCtaTitle;

  /// No description provided for @goalsCtaBody.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma fila deste escopo tem metas. Abra a fila, vá em Configurações e use Metas de atendimento para acompanhar o cumprimento aqui.'**
  String get goalsCtaBody;

  /// No description provided for @staffTitle.
  ///
  /// In pt, this message translates to:
  /// **'Planejamento de equipe'**
  String get staffTitle;

  /// No description provided for @staffSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Quantos atendentes cada dia e hora exigem, comparado com quem realmente atendeu.'**
  String get staffSubtitle;

  /// No description provided for @staffServiceTime.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio de atendimento: {min} min ({samples} atendimentos)'**
  String staffServiceTime(String min, int samples);

  /// No description provided for @staffServiceNone.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio indisponível: são necessários pelo menos {min} atendimentos concluídos.'**
  String staffServiceNone(int min);

  /// No description provided for @staffOccupancy.
  ///
  /// In pt, this message translates to:
  /// **'Ocupação-alvo: {pct}%'**
  String staffOccupancy(int pct);

  /// No description provided for @staffCoverage.
  ///
  /// In pt, this message translates to:
  /// **'Base: {days} dias com dados'**
  String staffCoverage(int days);

  /// No description provided for @staffModeRequired.
  ///
  /// In pt, this message translates to:
  /// **'Recomendado'**
  String get staffModeRequired;

  /// No description provided for @staffModeObserved.
  ///
  /// In pt, this message translates to:
  /// **'Observado'**
  String get staffModeObserved;

  /// No description provided for @staffModeGap.
  ///
  /// In pt, this message translates to:
  /// **'Diferença'**
  String get staffModeGap;

  /// No description provided for @staffGridTitle.
  ///
  /// In pt, this message translates to:
  /// **'Atendentes por dia e hora'**
  String get staffGridTitle;

  /// No description provided for @staffHintRequired.
  ///
  /// In pt, this message translates to:
  /// **'Atendentes recomendados para absorver a demanda média, com ocupação-alvo de {pct}%.'**
  String staffHintRequired(int pct);

  /// No description provided for @staffHintObserved.
  ///
  /// In pt, this message translates to:
  /// **'Média de atendentes distintos que atenderam em cada dia e hora.'**
  String get staffHintObserved;

  /// No description provided for @staffHintGap.
  ///
  /// In pt, this message translates to:
  /// **'Recomendado menos observado. Positivo: falta gente. Negativo: folga.'**
  String get staffHintGap;

  /// No description provided for @staffLegendDeficit.
  ///
  /// In pt, this message translates to:
  /// **'Falta'**
  String get staffLegendDeficit;

  /// No description provided for @staffLegendOk.
  ///
  /// In pt, this message translates to:
  /// **'Equilibrado'**
  String get staffLegendOk;

  /// No description provided for @staffLegendSurplus.
  ///
  /// In pt, this message translates to:
  /// **'Folga'**
  String get staffLegendSurplus;

  /// No description provided for @staffCellSpoken.
  ///
  /// In pt, this message translates to:
  /// **'{day} {hour}: recomendado {required}, observado {observed}'**
  String staffCellSpoken(
    String day,
    String hour,
    int required,
    String observed,
  );

  /// No description provided for @staffGridSpoken.
  ///
  /// In pt, this message translates to:
  /// **'Grade de atendentes por dia da semana e hora, modo {mode}. {top}'**
  String staffGridSpoken(String mode, String top);

  /// No description provided for @staffTopTitle.
  ///
  /// In pt, this message translates to:
  /// **'Maiores déficits'**
  String get staffTopTitle;

  /// No description provided for @staffTopRow.
  ///
  /// In pt, this message translates to:
  /// **'{day} {hour}: precisa de {required}, tem {observed}'**
  String staffTopRow(String day, String hour, int required, String observed);

  /// No description provided for @staffTopNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum déficit: a equipe observada cobre a demanda recomendada.'**
  String get staffTopNone;

  /// No description provided for @staffNoData.
  ///
  /// In pt, this message translates to:
  /// **'Sem chegadas no período para dimensionar a equipe.'**
  String get staffNoData;

  /// No description provided for @staffSeasonTitle.
  ///
  /// In pt, this message translates to:
  /// **'Volume semanal e sazonalidade'**
  String get staffSeasonTitle;

  /// No description provided for @staffSeasonInsufficient.
  ///
  /// In pt, this message translates to:
  /// **'Dados insuficientes: são necessárias pelo menos {need} semanas completas com dados (há {have}).'**
  String staffSeasonInsufficient(int need, int have);

  /// No description provided for @staffTrendUp.
  ///
  /// In pt, this message translates to:
  /// **'Tendência de alta: cerca de +{pct}% por semana.'**
  String staffTrendUp(String pct);

  /// No description provided for @staffTrendDown.
  ///
  /// In pt, this message translates to:
  /// **'Tendência de queda: cerca de {pct}% por semana.'**
  String staffTrendDown(String pct);

  /// No description provided for @staffTrendStable.
  ///
  /// In pt, this message translates to:
  /// **'Volume estável: variação abaixo de {pct}% por semana.'**
  String staffTrendStable(int pct);

  /// No description provided for @staffWeekSpoken.
  ///
  /// In pt, this message translates to:
  /// **'Semana de {date}: {count, plural, =1{1 chegada} other{{count} chegadas}}'**
  String staffWeekSpoken(String date, int count);

  /// No description provided for @staffRecurringTitle.
  ///
  /// In pt, this message translates to:
  /// **'Padrão recorrente'**
  String get staffRecurringTitle;

  /// No description provided for @staffRecurringRow.
  ///
  /// In pt, this message translates to:
  /// **'{day} {hour}: entre as mais cheias em {weeks} de {total} semanas'**
  String staffRecurringRow(String day, String hour, int weeks, int total);

  /// No description provided for @staffRecurringNone.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma hora se repete entre as mais cheias em pelo menos {pct}% das semanas.'**
  String staffRecurringNone(int pct);

  /// No description provided for @csvGoalIndicator.
  ///
  /// In pt, this message translates to:
  /// **'indicador'**
  String get csvGoalIndicator;

  /// No description provided for @csvEvaluated.
  ///
  /// In pt, this message translates to:
  /// **'avaliados'**
  String get csvEvaluated;

  /// No description provided for @csvWithinLimit.
  ///
  /// In pt, this message translates to:
  /// **'dentro do limite'**
  String get csvWithinLimit;

  /// No description provided for @csvPctWithinLimit.
  ///
  /// In pt, this message translates to:
  /// **'% dentro do limite'**
  String get csvPctWithinLimit;

  /// No description provided for @csvTargetPct.
  ///
  /// In pt, this message translates to:
  /// **'alvo %'**
  String get csvTargetPct;

  /// No description provided for @csvGoalMet.
  ///
  /// In pt, this message translates to:
  /// **'meta atingida'**
  String get csvGoalMet;

  /// No description provided for @csvWorstOverMin.
  ///
  /// In pt, this message translates to:
  /// **'maior violação (min)'**
  String get csvWorstOverMin;

  /// No description provided for @csvWorstDay.
  ///
  /// In pt, this message translates to:
  /// **'dia da maior violação'**
  String get csvWorstDay;

  /// No description provided for @csvMissedDays.
  ///
  /// In pt, this message translates to:
  /// **'dias abaixo do alvo'**
  String get csvMissedDays;

  /// No description provided for @csvMissedHours.
  ///
  /// In pt, this message translates to:
  /// **'horas abaixo do alvo'**
  String get csvMissedHours;

  /// No description provided for @csvArrivalsPerHour.
  ///
  /// In pt, this message translates to:
  /// **'chegadas por hora'**
  String get csvArrivalsPerHour;

  /// No description provided for @csvRequiredStaff.
  ///
  /// In pt, this message translates to:
  /// **'atendentes recomendados'**
  String get csvRequiredStaff;

  /// No description provided for @csvObservedStaff.
  ///
  /// In pt, this message translates to:
  /// **'atendentes observados'**
  String get csvObservedStaff;

  /// No description provided for @csvGapStaff.
  ///
  /// In pt, this message translates to:
  /// **'diferença'**
  String get csvGapStaff;

  /// No description provided for @csvWeekStart.
  ///
  /// In pt, this message translates to:
  /// **'início da semana'**
  String get csvWeekStart;

  /// No description provided for @csvTrendPct.
  ///
  /// In pt, this message translates to:
  /// **'tendência (% da média por semana)'**
  String get csvTrendPct;

  /// No description provided for @csvRecurringWeeks.
  ///
  /// In pt, this message translates to:
  /// **'semanas entre as mais cheias'**
  String get csvRecurringWeeks;

  /// No description provided for @csvOccupancyPct.
  ///
  /// In pt, this message translates to:
  /// **'ocupação-alvo %'**
  String get csvOccupancyPct;

  /// No description provided for @csvCoverageDays.
  ///
  /// In pt, this message translates to:
  /// **'dias com dados'**
  String get csvCoverageDays;

  /// No description provided for @biNameGoalWait.
  ///
  /// In pt, this message translates to:
  /// **'Espera dentro da meta'**
  String get biNameGoalWait;

  /// No description provided for @biWhatGoalWait.
  ///
  /// In pt, this message translates to:
  /// **'A parte dos atendimentos em que a pessoa esperou até o limite de espera definido na fila.'**
  String get biWhatGoalWait;

  /// No description provided for @biHowGoalWait.
  ///
  /// In pt, this message translates to:
  /// **'Compara a espera (chamada menos entrada) de cada atendido e não compareceu com a meta de espera. Quem desistiu só entra se esperou mais que a meta, e conta como descumprimento; desistência abaixo da meta e remoções do sistema ficam de fora. Percentual = dentro do limite ÷ avaliados. A meta é atingida quando o percentual alcança o alvo (padrão 80%). Com várias filas, cada pessoa é comparada à meta da própria fila e o alvo mostrado é a média ponderada pelos avaliados. Abaixo de {min} avaliados, o resultado é marcado como amostra pequena.'**
  String biHowGoalWait(int min);

  /// No description provided for @biDataGoalWait.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de entrada, de chamada e de saída (desistência) e as metas da fila. Sem telefone.'**
  String get biDataGoalWait;

  /// No description provided for @biUseGoalWait.
  ///
  /// In pt, this message translates to:
  /// **'Saber se o serviço está dentro do prazo prometido e quando ele falha.'**
  String get biUseGoalWait;

  /// No description provided for @biNameGoalService.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento dentro da meta'**
  String get biNameGoalService;

  /// No description provided for @biWhatGoalService.
  ///
  /// In pt, this message translates to:
  /// **'A parte dos atendimentos concluídos que durou até o tempo máximo definido na fila.'**
  String get biWhatGoalService;

  /// No description provided for @biHowGoalService.
  ///
  /// In pt, this message translates to:
  /// **'Só atendimentos concluídos (atendidos). Compara a duração (fim menos chamada) com a meta de atendimento. Percentual = dentro do limite ÷ avaliados; a meta é atingida quando alcança o alvo. Não comparecimentos e desistências não entram. Abaixo de {min} avaliados, o resultado é marcado como amostra pequena.'**
  String biHowGoalService(int min);

  /// No description provided for @biDataGoalService.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de chamada e de término e as metas da fila.'**
  String get biDataGoalService;

  /// No description provided for @biUseGoalService.
  ///
  /// In pt, this message translates to:
  /// **'Verificar se os atendimentos cabem no tempo esperado e achar dias e horas lentos.'**
  String get biUseGoalService;

  /// No description provided for @biNameGoalMissed.
  ///
  /// In pt, this message translates to:
  /// **'Períodos em que a meta não foi atingida'**
  String get biNameGoalMissed;

  /// No description provided for @biWhatGoalMissed.
  ///
  /// In pt, this message translates to:
  /// **'Dias e horas do dia em que o cumprimento ficou abaixo do alvo, e a maior violação.'**
  String get biWhatGoalMissed;

  /// No description provided for @biHowGoalMissed.
  ///
  /// In pt, this message translates to:
  /// **'Agrupa os avaliados por dia e por hora do dia (São Paulo). Lista os dias e as horas com pelo menos {min} avaliados e percentual abaixo do alvo. A maior violação é o maior excesso, em minutos, sobre o limite de espera ou de atendimento. Dias e horas com menos avaliados não são listados.'**
  String biHowGoalMissed(int min);

  /// No description provided for @biDataGoalMissed.
  ///
  /// In pt, this message translates to:
  /// **'Os mesmos dos indicadores de espera e de atendimento dentro da meta.'**
  String get biDataGoalMissed;

  /// No description provided for @biUseGoalMissed.
  ///
  /// In pt, this message translates to:
  /// **'Achar quando a meta falha de forma recorrente e reforçar a equipe nesses períodos.'**
  String get biUseGoalMissed;

  /// No description provided for @biNameStaffingService.
  ///
  /// In pt, this message translates to:
  /// **'Tempo médio de atendimento'**
  String get biNameStaffingService;

  /// No description provided for @biWhatStaffingService.
  ///
  /// In pt, this message translates to:
  /// **'A duração média dos atendimentos concluídos, usada para estimar quantos atendentes são necessários.'**
  String get biWhatStaffingService;

  /// No description provided for @biHowStaffingService.
  ///
  /// In pt, this message translates to:
  /// **'Média de fim menos chamada dos atendimentos concluídos (atendidos) do escopo e período. Com menos de {min} atendimentos não é calculada e a recomendação de atendentes fica indisponível.'**
  String biHowStaffingService(int min);

  /// No description provided for @biDataStaffingService.
  ///
  /// In pt, this message translates to:
  /// **'Resultado, horário de chamada e de término.'**
  String get biDataStaffingService;

  /// No description provided for @biUseStaffingService.
  ///
  /// In pt, this message translates to:
  /// **'Servir de base para o cálculo de atendentes recomendados.'**
  String get biUseStaffingService;

  /// No description provided for @biNameStaffingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Atendentes recomendados'**
  String get biNameStaffingRequired;

  /// No description provided for @biWhatStaffingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Quantos atendentes cada dia da semana e hora exigem para absorver a demanda média.'**
  String get biWhatStaffingRequired;

  /// No description provided for @biHowStaffingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Chegadas por hora = chegadas naquele dia da semana e hora ÷ número de vezes que esse dia da semana ocorre entre o primeiro e o último dia com dados (inclui quem desistiu e não compareceu). Recomendados = arredondar para cima (chegadas por hora × tempo médio de atendimento em horas ÷ ocupação-alvo de {pct}%). Indisponível sem tempo médio de atendimento.'**
  String biHowStaffingRequired(int pct);

  /// No description provided for @biDataStaffingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Hora de entrada de todas as pessoas, resultado, horário de chamada e de término.'**
  String get biDataStaffingRequired;

  /// No description provided for @biUseStaffingRequired.
  ///
  /// In pt, this message translates to:
  /// **'Montar escalas: ver em que dias e horas a equipe precisa ser maior.'**
  String get biUseStaffingRequired;

  /// No description provided for @biNameStaffingObserved.
  ///
  /// In pt, this message translates to:
  /// **'Atendentes observados'**
  String get biNameStaffingObserved;

  /// No description provided for @biWhatStaffingObserved.
  ///
  /// In pt, this message translates to:
  /// **'Quantos atendentes distintos realmente atenderam em cada dia da semana e hora.'**
  String get biWhatStaffingObserved;

  /// No description provided for @biHowStaffingObserved.
  ///
  /// In pt, this message translates to:
  /// **'Para cada data e hora, conta os atendentes distintos com atendimento em andamento, da chamada ao fim (atendimentos longos contam em todas as horas que atravessam). Soma por dia da semana e hora e divide pelo mesmo número de ocorrências do dia da semana usado nas chegadas. O dono e registros sem atendente contam como um atendente.'**
  String get biHowStaffingObserved;

  /// No description provided for @biDataStaffingObserved.
  ///
  /// In pt, this message translates to:
  /// **'Atendente, horário de chamada e de término, resultado (atendido ou não compareceu).'**
  String get biDataStaffingObserved;

  /// No description provided for @biUseStaffingObserved.
  ///
  /// In pt, this message translates to:
  /// **'Comparar a equipe que de fato atuou com a recomendada.'**
  String get biUseStaffingObserved;

  /// No description provided for @biNameStaffingGap.
  ///
  /// In pt, this message translates to:
  /// **'Déficit e folga'**
  String get biNameStaffingGap;

  /// No description provided for @biWhatStaffingGap.
  ///
  /// In pt, this message translates to:
  /// **'A diferença entre atendentes recomendados e observados em cada dia e hora.'**
  String get biWhatStaffingGap;

  /// No description provided for @biHowStaffingGap.
  ///
  /// In pt, this message translates to:
  /// **'Diferença = recomendados menos observados. Positivo é déficit (falta gente); negativo é folga. A lista mostra as {n} maiores diferenças positivas, desempatando por recomendados, dia e hora.'**
  String biHowStaffingGap(int n);

  /// No description provided for @biDataStaffingGap.
  ///
  /// In pt, this message translates to:
  /// **'Os mesmos dos atendentes recomendados e observados.'**
  String get biDataStaffingGap;

  /// No description provided for @biUseStaffingGap.
  ///
  /// In pt, this message translates to:
  /// **'Priorizar onde reforçar a equipe e onde sobra capacidade.'**
  String get biUseStaffingGap;

  /// No description provided for @biNameSeasonVolume.
  ///
  /// In pt, this message translates to:
  /// **'Volume semanal e tendência'**
  String get biNameSeasonVolume;

  /// No description provided for @biWhatSeasonVolume.
  ///
  /// In pt, this message translates to:
  /// **'Quantas pessoas entraram na fila em cada uma das últimas semanas e para onde o volume caminha.'**
  String get biWhatSeasonVolume;

  /// No description provided for @biHowSeasonVolume.
  ///
  /// In pt, this message translates to:
  /// **'Conta as chegadas (inclui desistências e não comparecimentos) por semana, de segunda a domingo (São Paulo), nas últimas {weeks} semanas completas, a partir da primeira semana com dados; a semana em andamento fica de fora. A tendência é a inclinação de uma reta ajustada aos volumes semanais, em % da média semanal por semana; abaixo de {band}% é considerada estável. Com menos de {min} semanas, mostra dados insuficientes.'**
  String biHowSeasonVolume(int weeks, int band, int min);

  /// No description provided for @biDataSeasonVolume.
  ///
  /// In pt, this message translates to:
  /// **'Hora de entrada de todas as pessoas. Usa todo o histórico carregado do escopo, não só o período escolhido.'**
  String get biDataSeasonVolume;

  /// No description provided for @biUseSeasonVolume.
  ///
  /// In pt, this message translates to:
  /// **'Planejar equipe e espaço para os próximos períodos.'**
  String get biUseSeasonVolume;

  /// No description provided for @biNameSeasonPattern.
  ///
  /// In pt, this message translates to:
  /// **'Padrão recorrente'**
  String get biNameSeasonPattern;

  /// No description provided for @biWhatSeasonPattern.
  ///
  /// In pt, this message translates to:
  /// **'Dias da semana e horas que se repetem entre os mais movimentados, semana após semana.'**
  String get biWhatSeasonPattern;

  /// No description provided for @biHowSeasonPattern.
  ///
  /// In pt, this message translates to:
  /// **'Em cada semana observada, pega as {top} células (dia da semana × hora) com mais chegadas. Uma célula é recorrente quando aparece nesse grupo em pelo menos {pct}% das semanas observadas. Exige ao menos {min} semanas.'**
  String biHowSeasonPattern(int top, int pct, int min);

  /// No description provided for @biDataSeasonPattern.
  ///
  /// In pt, this message translates to:
  /// **'Hora de entrada de todas as pessoas.'**
  String get biDataSeasonPattern;

  /// No description provided for @biUseSeasonPattern.
  ///
  /// In pt, this message translates to:
  /// **'Saber quais horários são movimentados sempre, e não por acaso.'**
  String get biUseSeasonPattern;
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
