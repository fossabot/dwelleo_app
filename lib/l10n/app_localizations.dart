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
