// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => '21 Sweet Pot';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionAccount => 'Cuenta';

  @override
  String get settingsSectionAvatarColor => 'Color del avatar';

  @override
  String get settingsSectionAppearance => 'Apariencia';

  @override
  String get settingsSectionLanguage => 'Idioma';

  @override
  String get settingsSectionSoundHaptics => 'Sonido y vibración';

  @override
  String get settingsSectionNotifications => 'Notificaciones';

  @override
  String get settingsSectionHelp => 'Ayuda';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get signingIn => 'Iniciando sesión…';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutConfirmTitle => '¿Cerrar sesión?';

  @override
  String get signOutConfirmMessage =>
      'Tus fichas y estadísticas permanecen en este dispositivo, pero abandonarás tu grupo de amigos y tu posición en la clasificación hasta que vuelvas a iniciar sesión.';

  @override
  String avatarColorSemanticLabel(int index, int total) {
    return 'Color de avatar $index de $total';
  }

  @override
  String get themeDefault => 'Predeterminado';

  @override
  String get themeOcean => 'Océano';

  @override
  String get themeEmber => 'Ascua';

  @override
  String themeFeltSemanticLabel(String label) {
    return 'Tapete $label';
  }

  @override
  String get hapticsLabel => 'Vibración';

  @override
  String get soundEffectsLabel => 'Efectos de sonido';

  @override
  String get voiceCalloutsLabel => 'Locución de voz';

  @override
  String get voiceCalloutsSublabel =>
      'Tu total de mano, los resultados y el bote se dicen en voz alta';

  @override
  String get voiceCalloutsDisabledReason =>
      'Activa los efectos de sonido para usar la locución de voz';

  @override
  String get notifSocialLabel => 'Social';

  @override
  String get notifSocialSublabel =>
      'Cuando un amigo se une a tu grupo, se conecta o te supera';

  @override
  String get notifLeaderboardLabel => 'Clasificación';

  @override
  String get notifLeaderboardSublabel =>
      'Cuando cambia tu posición en la tabla por hora o diaria';

  @override
  String get notifDailyLabel => 'Recordatorio diario';

  @override
  String get notifDailySublabel =>
      'Un aviso al día, cuando tu bono diario esté listo para reclamar';

  @override
  String get howToPlayLabel => 'Cómo jugar';

  @override
  String get howToPlaySublabel => 'Reglas, jugadas, pagos y el bote';

  @override
  String get replayTutorialLabel => 'Repetir el tutorial';

  @override
  String replayTutorialSublabel(int count) {
    return 'Tarjetas de ayuda en tus próximas $count manos';
  }

  @override
  String get termsOfServiceLabel => 'Términos del servicio';

  @override
  String get termsOfServiceSublabel => 'Lo que aceptas al jugar';

  @override
  String get privacyPolicyLabel => 'Política de privacidad';

  @override
  String get privacyPolicySublabel =>
      'Qué permanece en este dispositivo y qué no';

  @override
  String get versionLabel => 'Versión';

  @override
  String get resetBankrollConfirmTitle => '¿Reiniciar tu banca?';

  @override
  String get resetBankrollConfirmMessage =>
      'Tus fichas vuelven a 1000. Las estadísticas, premios, amigos y cosméticos no se ven afectados, pero las fichas que tienes ahora no se pueden recuperar.';

  @override
  String get resetBankrollConfirmLabel => 'Reiniciar fichas';

  @override
  String get resetBankrollButtonLabel => 'Reiniciar banca a 1000 fichas';

  @override
  String get languagePickerSublabel =>
      'Los menús y la voz del crupier siguen esta opción';

  @override
  String get languageSystemDefault => 'Igual que el idioma del dispositivo';

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
