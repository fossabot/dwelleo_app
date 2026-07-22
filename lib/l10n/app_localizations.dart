import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dwelleo'**
  String get appName;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseLanguage;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @iAmLookingTo.
  ///
  /// In en, this message translates to:
  /// **'I am looking to…'**
  String get iAmLookingTo;

  /// No description provided for @buyProperty.
  ///
  /// In en, this message translates to:
  /// **'Buy a Property'**
  String get buyProperty;

  /// No description provided for @rentProperty.
  ///
  /// In en, this message translates to:
  /// **'Rent a Property'**
  String get rentProperty;

  /// No description provided for @sellProperty.
  ///
  /// In en, this message translates to:
  /// **'Sell / List a Property'**
  String get sellProperty;

  /// No description provided for @developerBroker.
  ///
  /// In en, this message translates to:
  /// **'Developer / Broker'**
  String get developerBroker;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @developers.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get developers;

  /// No description provided for @aiSearch.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearch;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @bedrooms.
  ///
  /// In en, this message translates to:
  /// **'Bedrooms'**
  String get bedrooms;

  /// No description provided for @bathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get bathrooms;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @forSale.
  ///
  /// In en, this message translates to:
  /// **'For Sale'**
  String get forSale;

  /// No description provided for @forRent.
  ///
  /// In en, this message translates to:
  /// **'For Rent'**
  String get forRent;

  /// No description provided for @offPlan.
  ///
  /// In en, this message translates to:
  /// **'Off-Plan'**
  String get offPlan;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @contactAgent.
  ///
  /// In en, this message translates to:
  /// **'Contact Agent'**
  String get contactAgent;

  /// No description provided for @callNow.
  ///
  /// In en, this message translates to:
  /// **'Call Now'**
  String get callNow;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @shareProperty.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareProperty;

  /// No description provided for @saveProperty.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveProperty;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get errorUnauthorized;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @aiSearchShort.
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearchShort;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @heroTitleLead.
  ///
  /// In en, this message translates to:
  /// **'Find What You Need'**
  String get heroTitleLead;

  /// No description provided for @heroTitleAccent.
  ///
  /// In en, this message translates to:
  /// **'with Confidence'**
  String get heroTitleAccent;

  /// No description provided for @heroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Whether searching, investing, or listing — Dwelleo\'s AI-driven insights help you decide fast, clear, and simple.'**
  String get heroSubtitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'City, area or project'**
  String get searchHint;

  /// No description provided for @tryAiSearch.
  ///
  /// In en, this message translates to:
  /// **'Try AI Search'**
  String get tryAiSearch;

  /// No description provided for @quickPriceStats.
  ///
  /// In en, this message translates to:
  /// **'Price Statistics'**
  String get quickPriceStats;

  /// No description provided for @quickApartmentsRiyadh.
  ///
  /// In en, this message translates to:
  /// **'Apartments in Riyadh'**
  String get quickApartmentsRiyadh;

  /// No description provided for @quickVillasJeddah.
  ///
  /// In en, this message translates to:
  /// **'Villas in Jeddah'**
  String get quickVillasJeddah;

  /// No description provided for @quickOffPlanProjects.
  ///
  /// In en, this message translates to:
  /// **'Off-Plan Projects'**
  String get quickOffPlanProjects;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @aiBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet the AI Sales Agent'**
  String get aiBannerTitle;

  /// No description provided for @aiBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Answers every buyer instantly in Arabic and English — 24/7.'**
  String get aiBannerBody;

  /// No description provided for @excellentProperties.
  ///
  /// In en, this message translates to:
  /// **'Some Excellent Properties'**
  String get excellentProperties;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @exploreProjectsLead.
  ///
  /// In en, this message translates to:
  /// **'Explore Projects by'**
  String get exploreProjectsLead;

  /// No description provided for @exploreProjectsAccent.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get exploreProjectsAccent;

  /// No description provided for @exploreProjectsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse developments across prime locations, tailored to your lifestyle and investment goals.'**
  String get exploreProjectsSubtitle;

  /// No description provided for @startingFrom.
  ///
  /// In en, this message translates to:
  /// **'Starting From'**
  String get startingFrom;

  /// No description provided for @cityIntelligenceLead.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityIntelligenceLead;

  /// No description provided for @cityIntelligenceAccent.
  ///
  /// In en, this message translates to:
  /// **'intelligence.'**
  String get cityIntelligenceAccent;

  /// No description provided for @cityIntelligenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live average price per square meter across Saudi cities.'**
  String get cityIntelligenceSubtitle;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @villa.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// No description provided for @marketLeader.
  ///
  /// In en, this message translates to:
  /// **'Market leader'**
  String get marketLeader;

  /// No description provided for @sarPerSqm.
  ///
  /// In en, this message translates to:
  /// **'SAR / m²'**
  String get sarPerSqm;

  /// No description provided for @sortedByPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Sorted by price · highest first'**
  String get sortedByPriceDesc;

  /// No description provided for @sourceDwelleoIndex.
  ///
  /// In en, this message translates to:
  /// **'Source: Dwelleo Index'**
  String get sourceDwelleoIndex;

  /// No description provided for @featuredDevelopersLead.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredDevelopersLead;

  /// No description provided for @featuredDevelopersAccent.
  ///
  /// In en, this message translates to:
  /// **'Developers'**
  String get featuredDevelopersAccent;

  /// No description provided for @featuredDevelopersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Meet the trusted partners shaping the future of real estate with Dwelleo.'**
  String get featuredDevelopersSubtitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @aiSearchStubBody.
  ///
  /// In en, this message translates to:
  /// **'AI-powered text and voice property search is on the way.'**
  String get aiSearchStubBody;

  /// No description provided for @profileStubBody.
  ///
  /// In en, this message translates to:
  /// **'Your account, listings and settings will live here.'**
  String get profileStubBody;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved properties yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any property to keep it here.'**
  String get savedEmptyBody;

  /// No description provided for @browseProperties.
  ///
  /// In en, this message translates to:
  /// **'Browse Properties'**
  String get browseProperties;

  /// No description provided for @propertiesForSale.
  ///
  /// In en, this message translates to:
  /// **'Properties for Sale'**
  String get propertiesForSale;

  /// No description provided for @propertiesForRent.
  ///
  /// In en, this message translates to:
  /// **'Properties for Rent'**
  String get propertiesForRent;

  /// No description provided for @badgeSale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get badgeSale;

  /// No description provided for @badgeRent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get badgeRent;

  /// No description provided for @beds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get beds;

  /// No description provided for @baths.
  ///
  /// In en, this message translates to:
  /// **'Baths'**
  String get baths;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @subscriptionsStubBody.
  ///
  /// In en, this message translates to:
  /// **'Plans and pricing will appear here as soon as they go live.'**
  String get subscriptionsStubBody;

  /// No description provided for @aiSalesAgent.
  ///
  /// In en, this message translates to:
  /// **'AI Sales Agent'**
  String get aiSalesAgent;

  /// No description provided for @commercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get commercial;

  /// No description provided for @propertyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Property Type'**
  String get propertyTypeLabel;

  /// No description provided for @listingLabel.
  ///
  /// In en, this message translates to:
  /// **'Listing'**
  String get listingLabel;

  /// No description provided for @latestSearches.
  ///
  /// In en, this message translates to:
  /// **'Latest searches'**
  String get latestSearches;

  /// No description provided for @marketDataTag.
  ///
  /// In en, this message translates to:
  /// **'Market Data'**
  String get marketDataTag;

  /// No description provided for @cityIntelligenceSubtitleCount.
  ///
  /// In en, this message translates to:
  /// **'Live average price per square meter across {count} Saudi cities.'**
  String cityIntelligenceSubtitleCount(String count);

  /// No description provided for @avgPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Average price · {type} {listing}'**
  String avgPriceTitle(String type, String listing);

  /// No description provided for @toBuy.
  ///
  /// In en, this message translates to:
  /// **'to buy'**
  String get toBuy;

  /// No description provided for @toRent.
  ///
  /// In en, this message translates to:
  /// **'to rent'**
  String get toRent;

  /// No description provided for @sarPerMonth.
  ///
  /// In en, this message translates to:
  /// **'SAR / mo'**
  String get sarPerMonth;

  /// No description provided for @marketIntelligenceTag.
  ///
  /// In en, this message translates to:
  /// **'Dwelleo Market Intelligence'**
  String get marketIntelligenceTag;

  /// No description provided for @interactiveMarketMap.
  ///
  /// In en, this message translates to:
  /// **'Interactive Market map'**
  String get interactiveMarketMap;

  /// No description provided for @marketMapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Understand trends, forecast opportunities, and make informed real-estate decisions with Dwelleo\'s data-driven insights.'**
  String get marketMapSubtitle;

  /// No description provided for @heatmapIntensity.
  ///
  /// In en, this message translates to:
  /// **'Heatmap Intensity'**
  String get heatmapIntensity;

  /// No description provided for @lowLabel.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowLabel;

  /// No description provided for @highLabel.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highLabel;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @backToCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get backToCities;

  /// No description provided for @topDevelopers.
  ///
  /// In en, this message translates to:
  /// **'Top Real Estate Developers'**
  String get topDevelopers;

  /// No description provided for @topBrokers.
  ///
  /// In en, this message translates to:
  /// **'Top Real Estate Brokers'**
  String get topBrokers;

  /// No description provided for @featuredBrokersLead.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredBrokersLead;

  /// No description provided for @featuredBrokersAccent.
  ///
  /// In en, this message translates to:
  /// **'Brokers'**
  String get featuredBrokersAccent;

  /// No description provided for @maidRooms.
  ///
  /// In en, this message translates to:
  /// **'Maid Rooms'**
  String get maidRooms;

  /// No description provided for @driverRooms.
  ///
  /// In en, this message translates to:
  /// **'Driver Rooms'**
  String get driverRooms;

  /// No description provided for @developerLabel.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerLabel;

  /// No description provided for @expectedHandover.
  ///
  /// In en, this message translates to:
  /// **'Expected Handover'**
  String get expectedHandover;

  /// No description provided for @viewProperties.
  ///
  /// In en, this message translates to:
  /// **'View Properties'**
  String get viewProperties;

  /// No description provided for @viewPropertiesHint.
  ///
  /// In en, this message translates to:
  /// **'Opens this partner\'s live listings'**
  String get viewPropertiesHint;

  /// No description provided for @recenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenter;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showResults.
  ///
  /// In en, this message translates to:
  /// **'Show Results'**
  String get showResults;

  /// No description provided for @savedSearches.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get savedSearches;

  /// No description provided for @saveSearch.
  ///
  /// In en, this message translates to:
  /// **'Save this search'**
  String get saveSearch;

  /// No description provided for @searchSaved.
  ///
  /// In en, this message translates to:
  /// **'Search saved — find it in Filters.'**
  String get searchSaved;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String resultsCount(String count);

  /// No description provided for @priceRangeSar.
  ///
  /// In en, this message translates to:
  /// **'Price (SAR)'**
  String get priceRangeSar;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxPrice;

  /// No description provided for @furnishing.
  ///
  /// In en, this message translates to:
  /// **'Furnishing'**
  String get furnishing;

  /// No description provided for @furnishingUnfurnished.
  ///
  /// In en, this message translates to:
  /// **'Unfurnished'**
  String get furnishingUnfurnished;

  /// No description provided for @furnishingSemi.
  ///
  /// In en, this message translates to:
  /// **'Semi-furnished'**
  String get furnishingSemi;

  /// No description provided for @furnishingPartially.
  ///
  /// In en, this message translates to:
  /// **'Partially furnished'**
  String get furnishingPartially;

  /// No description provided for @contactUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Contact details are not available for this listing.'**
  String get contactUnavailable;

  /// No description provided for @aiWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Property Search'**
  String get aiWelcomeTitle;

  /// No description provided for @aiWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI-powered real estate assistant'**
  String get aiWelcomeSubtitle;

  /// No description provided for @aiWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Search for properties by voice or text, and Dwelleo helps you find your dream home with ease.'**
  String get aiWelcomeBody;

  /// No description provided for @aiWelcomeTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: You can type your query or use the microphone button to speak naturally'**
  String get aiWelcomeTip;

  /// No description provided for @aiTryAsking.
  ///
  /// In en, this message translates to:
  /// **'Try asking me:'**
  String get aiTryAsking;

  /// No description provided for @aiSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'3 bedroom apartments in Riyadh'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Cheapest villas for rent'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Properties with pool and gym'**
  String get aiSuggestion3;

  /// No description provided for @aiSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Office space in King Abdullah Financial District'**
  String get aiSuggestion4;

  /// No description provided for @aiSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Luxury penthouse above 10 million'**
  String get aiSuggestion5;

  /// No description provided for @aiSuggestion6.
  ///
  /// In en, this message translates to:
  /// **'Furnished apartments in Riyadh'**
  String get aiSuggestion6;

  /// No description provided for @aiComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the property you\'re looking for…'**
  String get aiComposerHint;

  /// No description provided for @aiListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get aiListening;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Searching live listings…'**
  String get aiThinking;

  /// No description provided for @aiUnderstoodIntro.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what I understood:'**
  String get aiUnderstoodIntro;

  /// No description provided for @aiNoSignal.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t catch a city, property type, bedrooms or price in that. Try something like the suggestions below.'**
  String get aiNoSignal;

  /// No description provided for @aiMicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn\'t available on this device — you can still type.'**
  String get aiMicUnavailable;

  /// No description provided for @aiViewAllResults.
  ///
  /// In en, this message translates to:
  /// **'View all {count} results'**
  String aiViewAllResults(String count);

  /// No description provided for @aiFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String aiFromPrice(String price);

  /// No description provided for @aiUpToPrice.
  ///
  /// In en, this message translates to:
  /// **'Up to {price}'**
  String aiUpToPrice(String price);

  /// No description provided for @aiReplyFound.
  ///
  /// In en, this message translates to:
  /// **'I found {count} matching properties — here are my top picks.'**
  String aiReplyFound(String count);

  /// No description provided for @aiReplyNone.
  ///
  /// In en, this message translates to:
  /// **'I couldn\'t find matches for that. Try adjusting the city, type or budget.'**
  String get aiReplyNone;

  /// No description provided for @aiAskListing.
  ///
  /// In en, this message translates to:
  /// **'Are you looking to rent or buy?'**
  String get aiAskListing;

  /// No description provided for @aiVoiceReplies.
  ///
  /// In en, this message translates to:
  /// **'Voice replies'**
  String get aiVoiceReplies;

  /// No description provided for @salesDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Demo assistant powered by a third-party AI model — not Dwelleo\'s production Sales Agent. It won\'t quote prices or legal terms.'**
  String get salesDisclosure;

  /// No description provided for @salesKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'The AI Sales Agent isn\'t enabled in this build. Run the app with --dart-define=GROQ_API_KEY=<your key>.'**
  String get salesKeyMissing;

  /// No description provided for @salesKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'The AI key was rejected — check your GROQ_API_KEY.'**
  String get salesKeyInvalid;

  /// No description provided for @salesQuotaMessage.
  ///
  /// In en, this message translates to:
  /// **'The demo AI rate limit was hit — wait a moment, then try again.'**
  String get salesQuotaMessage;

  /// No description provided for @salesThinking.
  ///
  /// In en, this message translates to:
  /// **'Your agent is typing…'**
  String get salesThinking;

  /// No description provided for @salesComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Tell your agent what you\'re looking for…'**
  String get salesComposerHint;

  /// No description provided for @salesSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'I have a 2M SAR budget and want a villa in Riyadh within 3 months'**
  String get salesSuggestion1;

  /// No description provided for @salesSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Looking for an apartment to invest in Jeddah'**
  String get salesSuggestion2;

  /// No description provided for @salesSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'What do I need to buy an off-plan unit?'**
  String get salesSuggestion3;

  /// No description provided for @salesResults.
  ///
  /// In en, this message translates to:
  /// **'Dwelleo results'**
  String get salesResults;

  /// No description provided for @salesOpensInApp.
  ///
  /// In en, this message translates to:
  /// **'Opens in app'**
  String get salesOpensInApp;

  /// No description provided for @salesLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied — this page opens on the website.'**
  String get salesLinkCopied;

  /// No description provided for @salesHistory.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get salesHistory;

  /// No description provided for @salesTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Sales Agent'**
  String get salesTabLabel;

  /// No description provided for @salesPersonaName.
  ///
  /// In en, this message translates to:
  /// **'Sarah'**
  String get salesPersonaName;

  /// No description provided for @salesOnline.
  ///
  /// In en, this message translates to:
  /// **'Online · replies 24/7'**
  String get salesOnline;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// No description provided for @docs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get docs;

  /// No description provided for @salesVisitPrompt.
  ///
  /// In en, this message translates to:
  /// **'I\'d like to book a site visit'**
  String get salesVisitPrompt;

  /// No description provided for @salesDocsPrompt.
  ///
  /// In en, this message translates to:
  /// **'What documents do I need to proceed?'**
  String get salesDocsPrompt;

  /// No description provided for @salesHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved conversations yet — your chats with the agent will appear here.'**
  String get salesHistoryEmpty;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @leadProfile.
  ///
  /// In en, this message translates to:
  /// **'Lead profile'**
  String get leadProfile;

  /// No description provided for @leadBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get leadBudget;

  /// No description provided for @leadIntent.
  ///
  /// In en, this message translates to:
  /// **'Intent'**
  String get leadIntent;

  /// No description provided for @leadTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get leadTimeline;

  /// No description provided for @leadEligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get leadEligibility;

  /// No description provided for @leadPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get leadPreferences;

  /// No description provided for @insightsAiPricePrediction.
  ///
  /// In en, this message translates to:
  /// **'AI Price Prediction'**
  String get insightsAiPricePrediction;

  /// No description provided for @insightsPredictedPrice.
  ///
  /// In en, this message translates to:
  /// **'predicted price'**
  String get insightsPredictedPrice;

  /// No description provided for @insightsRange.
  ///
  /// In en, this message translates to:
  /// **'Predicted range'**
  String get insightsRange;

  /// No description provided for @insightsInvestmentScore.
  ///
  /// In en, this message translates to:
  /// **'Investment Score'**
  String get insightsInvestmentScore;

  /// No description provided for @insightsLifestyleScore.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle Score'**
  String get insightsLifestyleScore;

  /// No description provided for @insightsSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar Properties'**
  String get insightsSimilar;

  /// No description provided for @tierExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get tierExcellent;

  /// No description provided for @tierGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get tierGood;

  /// No description provided for @tierFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get tierFair;

  /// No description provided for @tierWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get tierWeak;

  /// No description provided for @factorValue.
  ///
  /// In en, this message translates to:
  /// **'Value vs market'**
  String get factorValue;

  /// No description provided for @factorIncome.
  ///
  /// In en, this message translates to:
  /// **'Income return'**
  String get factorIncome;

  /// No description provided for @factorLocation.
  ///
  /// In en, this message translates to:
  /// **'Location quality'**
  String get factorLocation;

  /// No description provided for @factorSaturation.
  ///
  /// In en, this message translates to:
  /// **'Market saturation'**
  String get factorSaturation;

  /// No description provided for @lifeWalkability.
  ///
  /// In en, this message translates to:
  /// **'Walkability'**
  String get lifeWalkability;

  /// No description provided for @lifeActivity.
  ///
  /// In en, this message translates to:
  /// **'Area activity'**
  String get lifeActivity;

  /// No description provided for @lifeWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get lifeWellness;

  /// No description provided for @lifeNoise.
  ///
  /// In en, this message translates to:
  /// **'Noise level'**
  String get lifeNoise;

  /// No description provided for @lifeBike.
  ///
  /// In en, this message translates to:
  /// **'Bikeability'**
  String get lifeBike;

  /// No description provided for @lifeTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get lifeTransport;

  /// No description provided for @brokers.
  ///
  /// In en, this message translates to:
  /// **'Brokers'**
  String get brokers;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @compare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare;

  /// No description provided for @compareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare properties'**
  String get compareTitle;

  /// No description provided for @compareEmpty.
  ///
  /// In en, this message translates to:
  /// **'Pick two properties to compare — tap the compare icon on any property page.'**
  String get compareEmpty;

  /// No description provided for @compareAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to compare'**
  String get compareAdded;

  /// No description provided for @compareRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from compare'**
  String get compareRemoved;

  /// No description provided for @launchDate.
  ///
  /// In en, this message translates to:
  /// **'Launch date'**
  String get launchDate;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key features'**
  String get keyFeatures;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @searchDevelopersHint.
  ///
  /// In en, this message translates to:
  /// **'Search developers or brokers'**
  String get searchDevelopersHint;

  /// No description provided for @searchProjectsHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects by name or city'**
  String get searchProjectsHint;

  /// No description provided for @searchPropertiesHint.
  ///
  /// In en, this message translates to:
  /// **'Search by city or district'**
  String get searchPropertiesHint;

  /// No description provided for @sar.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get sar;

  /// No description provided for @sqm.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get sqm;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @estimateProperty.
  ///
  /// In en, this message translates to:
  /// **'Estimate Property'**
  String get estimateProperty;

  /// No description provided for @estimateStepOf.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String estimateStepOf(int step, int total);

  /// No description provided for @estimateOptional.
  ///
  /// In en, this message translates to:
  /// **'OPTIONAL'**
  String get estimateOptional;

  /// No description provided for @estimatePurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to do?'**
  String get estimatePurposeTitle;

  /// No description provided for @estimatePurposeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We tailor your estimate and next steps to your goal.'**
  String get estimatePurposeSubtitle;

  /// No description provided for @estimateSell.
  ///
  /// In en, this message translates to:
  /// **'Sell my property'**
  String get estimateSell;

  /// No description provided for @estimateSellHint.
  ///
  /// In en, this message translates to:
  /// **'Get a suggested asking price'**
  String get estimateSellHint;

  /// No description provided for @estimateRent.
  ///
  /// In en, this message translates to:
  /// **'Rent my property'**
  String get estimateRent;

  /// No description provided for @estimateRentHint.
  ///
  /// In en, this message translates to:
  /// **'Expected rent & yield'**
  String get estimateRentHint;

  /// No description provided for @estimateLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Property location'**
  String get estimateLocationTitle;

  /// No description provided for @estimateLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Location is the biggest price driver — pick the district precisely.'**
  String get estimateLocationSubtitle;

  /// No description provided for @estimateGateLocation.
  ///
  /// In en, this message translates to:
  /// **'Select city and district to continue'**
  String get estimateGateLocation;

  /// No description provided for @estimateTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get estimateTypeTitle;

  /// No description provided for @estimateTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick what best matches your property.'**
  String get estimateTypeSubtitle;

  /// No description provided for @estimateTypesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Penthouse · Studio · Rest house · Commercial — coming soon'**
  String get estimateTypesComingSoon;

  /// No description provided for @estimateDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get estimateDetailsTitle;

  /// No description provided for @estimateDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each field shows how strongly it affects the estimate.'**
  String get estimateDetailsSubtitle;

  /// No description provided for @estimateGateDetails.
  ///
  /// In en, this message translates to:
  /// **'Add the floor area and bedrooms to continue'**
  String get estimateGateDetails;

  /// No description provided for @estimateAreaAndRooms.
  ///
  /// In en, this message translates to:
  /// **'Area & rooms'**
  String get estimateAreaAndRooms;

  /// No description provided for @estimateFloorArea.
  ///
  /// In en, this message translates to:
  /// **'Floor area'**
  String get estimateFloorArea;

  /// No description provided for @estimateHighImpact.
  ///
  /// In en, this message translates to:
  /// **'HIGH IMPACT'**
  String get estimateHighImpact;

  /// No description provided for @estimateLivingRooms.
  ///
  /// In en, this message translates to:
  /// **'Living rooms'**
  String get estimateLivingRooms;

  /// No description provided for @estimateBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get estimateBuilding;

  /// No description provided for @estimateYearBuilt.
  ///
  /// In en, this message translates to:
  /// **'Year built'**
  String get estimateYearBuilt;

  /// No description provided for @estimateStreetsFacing.
  ///
  /// In en, this message translates to:
  /// **'Streets facing'**
  String get estimateStreetsFacing;

  /// No description provided for @estimateConditionTitle.
  ///
  /// In en, this message translates to:
  /// **'Interior & amenities'**
  String get estimateConditionTitle;

  /// No description provided for @estimateConditionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Condition and fit-out move the range.'**
  String get estimateConditionSubtitle;

  /// No description provided for @estimateInterior.
  ///
  /// In en, this message translates to:
  /// **'Interior'**
  String get estimateInterior;

  /// No description provided for @estimateFittedKitchen.
  ///
  /// In en, this message translates to:
  /// **'Fitted kitchen'**
  String get estimateFittedKitchen;

  /// No description provided for @estimateFurnished.
  ///
  /// In en, this message translates to:
  /// **'Furnished'**
  String get estimateFurnished;

  /// No description provided for @estimateAcInstalled.
  ///
  /// In en, this message translates to:
  /// **'AC installed'**
  String get estimateAcInstalled;

  /// No description provided for @estimateAcType.
  ///
  /// In en, this message translates to:
  /// **'AC type'**
  String get estimateAcType;

  /// No description provided for @estimateAcNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get estimateAcNone;

  /// No description provided for @estimateAcSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get estimateAcSplit;

  /// No description provided for @estimateAcCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get estimateAcCentral;

  /// No description provided for @estimateAcConcealed.
  ///
  /// In en, this message translates to:
  /// **'Concealed'**
  String get estimateAcConcealed;

  /// No description provided for @estimateFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Most impactful features'**
  String get estimateFeaturesTitle;

  /// No description provided for @estimateFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your estimate is ready after this step.'**
  String get estimateFeaturesSubtitle;

  /// No description provided for @estimateElevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get estimateElevator;

  /// No description provided for @estimateParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get estimateParking;

  /// No description provided for @estimateStorageRoom.
  ///
  /// In en, this message translates to:
  /// **'Storage room'**
  String get estimateStorageRoom;

  /// No description provided for @estimateSecurity.
  ///
  /// In en, this message translates to:
  /// **'24/7 security'**
  String get estimateSecurity;

  /// No description provided for @estimateBoostTitle.
  ///
  /// In en, this message translates to:
  /// **'Improve your estimate\'s accuracy'**
  String get estimateBoostTitle;

  /// No description provided for @estimateBoostSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a few more characteristics to raise the confidence index.'**
  String get estimateBoostSubtitle;

  /// No description provided for @estimateImproveAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Improve accuracy (optional)'**
  String get estimateImproveAccuracy;

  /// No description provided for @estimateFacing.
  ///
  /// In en, this message translates to:
  /// **'Facing direction'**
  String get estimateFacing;

  /// No description provided for @estimateNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get estimateNorth;

  /// No description provided for @estimateEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get estimateEast;

  /// No description provided for @estimateSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get estimateSouth;

  /// No description provided for @estimateWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get estimateWest;

  /// No description provided for @estimateExtras.
  ///
  /// In en, this message translates to:
  /// **'Extras'**
  String get estimateExtras;

  /// No description provided for @estimateBalcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get estimateBalcony;

  /// No description provided for @estimateSeeResult.
  ///
  /// In en, this message translates to:
  /// **'See estimate'**
  String get estimateSeeResult;

  /// No description provided for @estimateAnalysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing market data…'**
  String get estimateAnalysing;

  /// No description provided for @estimateReady.
  ///
  /// In en, this message translates to:
  /// **'Estimate ready'**
  String get estimateReady;

  /// No description provided for @estimateRestart.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get estimateRestart;

  /// No description provided for @estimateResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your property\'s estimated price'**
  String get estimateResultTitle;

  /// No description provided for @estimateRentTitle.
  ///
  /// In en, this message translates to:
  /// **'Your property\'s expected rent'**
  String get estimateRentTitle;

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated price'**
  String get estimatedPrice;

  /// No description provided for @estimateAnnualRent.
  ///
  /// In en, this message translates to:
  /// **'Expected annual rent'**
  String get estimateAnnualRent;

  /// No description provided for @estimateNetYield.
  ///
  /// In en, this message translates to:
  /// **'Net rental yield'**
  String get estimateNetYield;

  /// No description provided for @estimateLowRange.
  ///
  /// In en, this message translates to:
  /// **'Low range'**
  String get estimateLowRange;

  /// No description provided for @estimateHighRange.
  ///
  /// In en, this message translates to:
  /// **'High range'**
  String get estimateHighRange;

  /// No description provided for @estimateConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence index'**
  String get estimateConfidence;

  /// No description provided for @estimateHighAccuracy.
  ///
  /// In en, this message translates to:
  /// **'High accuracy — advanced details completed'**
  String get estimateHighAccuracy;

  /// No description provided for @estimateAddDetails.
  ///
  /// In en, this message translates to:
  /// **'Add more details to raise accuracy'**
  String get estimateAddDetails;

  /// No description provided for @estimateWhy.
  ///
  /// In en, this message translates to:
  /// **'Why this estimate?'**
  String get estimateWhy;

  /// No description provided for @estimateFactorDistrict.
  ///
  /// In en, this message translates to:
  /// **'District average price'**
  String get estimateFactorDistrict;

  /// No description provided for @estimateFactorArea.
  ///
  /// In en, this message translates to:
  /// **'Floor area & rooms'**
  String get estimateFactorArea;

  /// No description provided for @estimateFactorAge.
  ///
  /// In en, this message translates to:
  /// **'Building age'**
  String get estimateFactorAge;

  /// No description provided for @estimateFactorAmenities.
  ///
  /// In en, this message translates to:
  /// **'Elevator, parking & amenities'**
  String get estimateFactorAmenities;

  /// No description provided for @estimatePositive.
  ///
  /// In en, this message translates to:
  /// **'Positive'**
  String get estimatePositive;

  /// No description provided for @estimateNegative.
  ///
  /// In en, this message translates to:
  /// **'Negative'**
  String get estimateNegative;

  /// No description provided for @estimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Indicative estimate based on Dwelleo market data — not an accredited valuation (Taqeem). For an official valuation, request a report from an accredited valuer.'**
  String get estimateDisclaimer;

  /// No description provided for @estimateTalkToAgent.
  ///
  /// In en, this message translates to:
  /// **'Discuss this with Sarah'**
  String get estimateTalkToAgent;

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @marketDataDriven.
  ///
  /// In en, this message translates to:
  /// **'DATA-DRIVEN INSIGHTS'**
  String get marketDataDriven;

  /// No description provided for @marketInsightsLead.
  ///
  /// In en, this message translates to:
  /// **'Real-Time Saudi'**
  String get marketInsightsLead;

  /// No description provided for @marketInsightsAccent.
  ///
  /// In en, this message translates to:
  /// **'Market Insights'**
  String get marketInsightsAccent;

  /// No description provided for @marketInsightsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live insights into the Saudi real estate market.'**
  String get marketInsightsSubtitle;

  /// No description provided for @marketTabTopCities.
  ///
  /// In en, this message translates to:
  /// **'Commercial Growth'**
  String get marketTabTopCities;

  /// No description provided for @marketTabHighestGrowth.
  ///
  /// In en, this message translates to:
  /// **'Highest Growth'**
  String get marketTabHighestGrowth;

  /// No description provided for @marketTabRegions.
  ///
  /// In en, this message translates to:
  /// **'By Region'**
  String get marketTabRegions;

  /// No description provided for @marketOverallGrowth.
  ///
  /// In en, this message translates to:
  /// **'OVERALL GROWTH'**
  String get marketOverallGrowth;

  /// No description provided for @marketBaseYear.
  ///
  /// In en, this message translates to:
  /// **'Base year'**
  String get marketBaseYear;

  /// No description provided for @marketLatestYear.
  ///
  /// In en, this message translates to:
  /// **'Latest year'**
  String get marketLatestYear;

  /// No description provided for @marketUnits.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get marketUnits;

  /// No description provided for @marketRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get marketRegion;

  /// No description provided for @marketUnitType.
  ///
  /// In en, this message translates to:
  /// **'Unit type'**
  String get marketUnitType;

  /// No description provided for @marketUnitPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get marketUnitPurpose;

  /// No description provided for @marketTierHigh.
  ///
  /// In en, this message translates to:
  /// **'50%+ growth'**
  String get marketTierHigh;

  /// No description provided for @marketTierMid.
  ///
  /// In en, this message translates to:
  /// **'25%+ growth'**
  String get marketTierMid;

  /// No description provided for @marketTierLow.
  ///
  /// In en, this message translates to:
  /// **'10%+ growth'**
  String get marketTierLow;

  /// No description provided for @marketTierFlat.
  ///
  /// In en, this message translates to:
  /// **'<10% growth'**
  String get marketTierFlat;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @nearbyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get nearbyPlaces;

  /// No description provided for @insightsAskingAbove.
  ///
  /// In en, this message translates to:
  /// **'Asking price is {pct}% above the AI prediction'**
  String insightsAskingAbove(int pct);

  /// No description provided for @insightsAskingBelow.
  ///
  /// In en, this message translates to:
  /// **'Asking price is {pct}% below the AI prediction'**
  String insightsAskingBelow(int pct);

  /// No description provided for @insightsAskingInline.
  ///
  /// In en, this message translates to:
  /// **'Asking price is in line with the AI prediction'**
  String get insightsAskingInline;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
