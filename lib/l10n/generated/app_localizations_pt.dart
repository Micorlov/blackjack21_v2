// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionAccount => 'Conta';

  @override
  String get settingsSectionAvatarColor => 'Cor do avatar';

  @override
  String get settingsSectionAppearance => 'Aparência';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionSoundHaptics => 'Som e vibração';

  @override
  String get settingsSectionNotifications => 'Notificações';

  @override
  String get settingsSectionHelp => 'Ajuda';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get signingIn => 'Entrando…';

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signOutConfirmTitle => 'Sair da conta?';

  @override
  String get signOutConfirmMessage =>
      'Suas fichas e estatísticas permanecem neste dispositivo, mas você sairá do seu grupo de amigos e da sua posição no ranking até entrar novamente.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Cor do avatar $index de $total';
  }

  @override
  String get themeDefault => 'Padrão';

  @override
  String get themeOcean => 'Oceano';

  @override
  String get themeEmber => 'Brasa';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Mesa $label';
  }

  @override
  String get hapticsLabel => 'Vibração';

  @override
  String get soundEffectsLabel => 'Efeitos sonoros';

  @override
  String get voiceCalloutsLabel => 'Locução por voz';

  @override
  String get voiceCalloutsSublabel =>
      'Seu total na mão, os resultados e o pote são ditos em voz alta';

  @override
  String get voiceCalloutsDisabledReason =>
      'Ative os efeitos sonoros para usar a locução por voz';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'Quando um amigo entra no seu grupo, fica online ou te ultrapassa';

  @override
  String get notifLeaderboardLabel => 'Ranking';

  @override
  String get notifLeaderboardSublabel =>
      'Quando sua posição no ranking horário ou diário muda';

  @override
  String get notifDailyLabel => 'Lembrete diário';

  @override
  String get notifDailySublabel =>
      'Um aviso por dia, assim que seu bônus diário estiver pronto';

  @override
  String get howToPlayLabel => 'Como jogar';

  @override
  String get howToPlaySublabel => 'Regras, jogadas, pagamentos e o pote';

  @override
  String get replayTutorialLabel => 'Repetir o tutorial';

  @override
  String replayTutorialSublabel(int count) {
    return 'Cartões de dicas nas suas próximas $count mãos';
  }

  @override
  String get termsOfServiceLabel => 'Termos de Serviço';

  @override
  String get termsOfServiceSublabel => 'O que você aceita ao jogar';

  @override
  String get privacyPolicyLabel => 'Política de Privacidade';

  @override
  String get privacyPolicySublabel =>
      'O que fica neste dispositivo e o que não fica';

  @override
  String get versionLabel => 'Versão';

  @override
  String get resetBankrollConfirmTitle => 'Reiniciar sua banca?';

  @override
  String get resetBankrollConfirmMessage =>
      'Suas fichas voltam para 1.000. Estatísticas, prêmios, amigos e cosméticos permanecem intactos, mas as fichas atuais não podem ser recuperadas.';

  @override
  String get resetBankrollConfirmLabel => 'Reiniciar fichas';

  @override
  String get resetBankrollButtonLabel => 'Reiniciar banca para 1.000 fichas';

  @override
  String get languagePickerSublabel =>
      'Os menus e a voz do dealer seguem esta escolha';

  @override
  String get languageSystemDefault => 'Usar idioma do dispositivo';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameEs => 'Español';

  @override
  String get languageNameFr => 'Français';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNamePt => 'Português';

  @override
  String get languageNameRu => 'Русский';

  @override
  String get languageNameZh => '中文';

  @override
  String get languageNameJa => '日本語';

  @override
  String get languageNameHe => 'עברית';

  @override
  String get languageNameAr => 'العربية';
}
