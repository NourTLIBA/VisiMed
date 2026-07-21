import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @quickDemoLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion Démo Rapide'**
  String get quickDemoLogin;

  /// No description provided for @demoCredentialsHint.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants de démo'**
  String get demoCredentialsHint;

  /// No description provided for @roleAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get roleAdmin;

  /// No description provided for @roleMedRep.
  ///
  /// In fr, this message translates to:
  /// **'Délégué Médical'**
  String get roleMedRep;

  /// No description provided for @rolePharmaRep.
  ///
  /// In fr, this message translates to:
  /// **'Délégué Pharmaceutique'**
  String get rolePharmaRep;

  /// No description provided for @loginFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion — vérifiez vos identifiants'**
  String get loginFailed;

  /// No description provided for @exportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter CSV'**
  String get exportCsv;

  /// No description provided for @appState.
  ///
  /// In fr, this message translates to:
  /// **'État de l\'App'**
  String get appState;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @adminArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace Admin'**
  String get adminArea;

  /// No description provided for @totalVisits.
  ///
  /// In fr, this message translates to:
  /// **'Total Visites'**
  String get totalVisits;

  /// No description provided for @activeReps.
  ///
  /// In fr, this message translates to:
  /// **'Délégués Actifs'**
  String get activeReps;

  /// No description provided for @productsGiven.
  ///
  /// In fr, this message translates to:
  /// **'Produits Distribués'**
  String get productsGiven;

  /// No description provided for @byType.
  ///
  /// In fr, this message translates to:
  /// **'Par Type'**
  String get byType;

  /// No description provided for @byPotential.
  ///
  /// In fr, this message translates to:
  /// **'Par Potentiel'**
  String get byPotential;

  /// No description provided for @medical.
  ///
  /// In fr, this message translates to:
  /// **'Médicale'**
  String get medical;

  /// No description provided for @pharmaceutical.
  ///
  /// In fr, this message translates to:
  /// **'Pharmaceutique'**
  String get pharmaceutical;

  /// No description provided for @recentVisits.
  ///
  /// In fr, this message translates to:
  /// **'Visites Récentes'**
  String get recentVisits;

  /// No description provided for @noVisitsMatched.
  ///
  /// In fr, this message translates to:
  /// **'Aucune visite ne correspond aux filtres.'**
  String get noVisitsMatched;

  /// No description provided for @newVisit.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Visite'**
  String get newVisit;

  /// No description provided for @saveVisit.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la Visite'**
  String get saveVisit;

  /// No description provided for @targetInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations Cible'**
  String get targetInformation;

  /// No description provided for @targetName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Médecin/Pharmacie'**
  String get targetName;

  /// No description provided for @structureType.
  ///
  /// In fr, this message translates to:
  /// **'Type de Structure'**
  String get structureType;

  /// No description provided for @specialty.
  ///
  /// In fr, this message translates to:
  /// **'Spécialité'**
  String get specialty;

  /// No description provided for @potential.
  ///
  /// In fr, this message translates to:
  /// **'Potentiel'**
  String get potential;

  /// No description provided for @patientLoad.
  ///
  /// In fr, this message translates to:
  /// **'Flux Patients (patients/jour)'**
  String get patientLoad;

  /// No description provided for @locationContact.
  ///
  /// In fr, this message translates to:
  /// **'Localisation & Contact'**
  String get locationContact;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @wilaya.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @commune.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @telephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get telephone;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @visitDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la Visite'**
  String get visitDetails;

  /// No description provided for @visitMaterialGiven.
  ///
  /// In fr, this message translates to:
  /// **'Matériel Remis'**
  String get visitMaterialGiven;

  /// No description provided for @qtyReader.
  ///
  /// In fr, this message translates to:
  /// **'Lecteurs'**
  String get qtyReader;

  /// No description provided for @qtyVials.
  ///
  /// In fr, this message translates to:
  /// **'Flacons'**
  String get qtyVials;

  /// No description provided for @qtyBrochureM.
  ///
  /// In fr, this message translates to:
  /// **'Brochures (Médecin)'**
  String get qtyBrochureM;

  /// No description provided for @qtyBrochurePatient.
  ///
  /// In fr, this message translates to:
  /// **'Brochures (Patient)'**
  String get qtyBrochurePatient;

  /// No description provided for @qtyAffiche.
  ///
  /// In fr, this message translates to:
  /// **'Affiches'**
  String get qtyAffiche;

  /// No description provided for @comment.
  ///
  /// In fr, this message translates to:
  /// **'Commentaire'**
  String get comment;

  /// No description provided for @requiredFieldsMissing.
  ///
  /// In fr, this message translates to:
  /// **'Des champs obligatoires sont manquants'**
  String get requiredFieldsMissing;

  /// No description provided for @saveFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de l\'enregistrement'**
  String get saveFailed;

  /// No description provided for @visitSavedSuccessfully.
  ///
  /// In fr, this message translates to:
  /// **'Visite enregistrée avec succès'**
  String get visitSavedSuccessfully;

  /// No description provided for @myVisits.
  ///
  /// In fr, this message translates to:
  /// **'Mes Visites'**
  String get myVisits;

  /// No description provided for @calendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get calendar;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @map.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get map;

  /// No description provided for @visits.
  ///
  /// In fr, this message translates to:
  /// **'Visites'**
  String get visits;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @noVisitsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune visite pour le moment'**
  String get noVisitsYet;

  /// No description provided for @tapBelowToLog.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur le bouton ci-dessous pour enregistrer votre première visite'**
  String get tapBelowToLog;

  /// No description provided for @selectADay.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un jour'**
  String get selectADay;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;
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
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
