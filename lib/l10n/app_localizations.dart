import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// App name shown in title bars
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get appTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get signInEmailLabel;

  /// No description provided for @signInPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get signInPasswordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get signUpPrompt;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// No description provided for @signUpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get signUpNameLabel;

  /// No description provided for @signUpNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Friends see this name in groups.'**
  String get signUpNameHelper;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get signInPrompt;

  /// Between the Google button and the email form
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orDivider;

  /// No description provided for @forgotPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordButton;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We\'ll send you a link to choose a new password.'**
  String get resetPasswordInstructions;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get resetPasswordCheckEmailTitle;

  /// Firebase email enumeration protection hides whether the account exists, so don't claim it was sent
  ///
  /// In en, this message translates to:
  /// **'If an account uses {email}, a reset link is on its way. Open it, choose a new password, then come back and sign in.'**
  String resetPasswordCheckEmailBody(String email);

  /// No description provided for @resetPasswordSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Not there after a few minutes? Check your spam folder.'**
  String get resetPasswordSpamHint;

  /// No description provided for @resetPasswordResend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get resetPasswordResend;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get backToSignIn;

  /// No description provided for @errorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get errorNameRequired;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordRequired;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get errorWrongPassword;

  /// No description provided for @errorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get errorUserNotFound;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get errorEmailInUse;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please try again.'**
  String get errorNetwork;

  /// Home greeting; the one Roman Urdu touch on this screen (DESIGN.md §10)
  ///
  /// In en, this message translates to:
  /// **'Salam, {name}'**
  String homeGreeting(String name);

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @createGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroupButton;

  /// No description provided for @joinWithCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCodeButton;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @createGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get createGroupTitle;

  /// No description provided for @groupNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupNameLabel;

  /// No description provided for @groupTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type (optional)'**
  String get groupTypeLabel;

  /// No description provided for @groupTypeHelper.
  ///
  /// In en, this message translates to:
  /// **'For example Trip or Home.'**
  String get groupTypeHelper;

  /// No description provided for @groupTypeFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get groupTypeFriends;

  /// No description provided for @groupTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get groupTypeTrip;

  /// No description provided for @groupTypeHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get groupTypeHome;

  /// No description provided for @groupTypeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get groupTypeOffice;

  /// No description provided for @groupTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get groupTypeFamily;

  /// No description provided for @errorGroupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a group name.'**
  String get errorGroupNameRequired;

  /// Success SnackBar; Roman Urdu touch (DESIGN.md §10)
  ///
  /// In en, this message translates to:
  /// **'Done! Group ban gaya'**
  String get groupCreated;

  /// No description provided for @groupSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTooltip;

  /// No description provided for @groupOnlyYou.
  ///
  /// In en, this message translates to:
  /// **'Add your friends to start splitting.'**
  String get groupOnlyYou;

  /// Empty expenses state; Roman Urdu touch
  ///
  /// In en, this message translates to:
  /// **'Abhi koi expense nahi.'**
  String get groupNoExpenses;

  /// No description provided for @inviteFriendsButton.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriendsButton;

  /// No description provided for @addByNameButton.
  ///
  /// In en, this message translates to:
  /// **'Add by name'**
  String get addByNameButton;

  /// No description provided for @groupSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettingsTitle;

  /// No description provided for @sectionGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get sectionGroup;

  /// No description provided for @sectionMembers.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String sectionMembers(int count);

  /// No description provided for @sectionInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get sectionInvite;

  /// No description provided for @joinCodeRow.
  ///
  /// In en, this message translates to:
  /// **'Join code {code}'**
  String joinCodeRow(String code);

  /// No description provided for @memberYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String memberYou(String name);

  /// No description provided for @memberNotJoined.
  ///
  /// In en, this message translates to:
  /// **'not joined yet'**
  String get memberNotJoined;

  /// No description provided for @memberLeft.
  ///
  /// In en, this message translates to:
  /// **'left the group'**
  String get memberLeft;

  /// No description provided for @editGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroupTitle;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @addPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add by name'**
  String get addPlaceholderTitle;

  /// No description provided for @addPlaceholderHelper.
  ///
  /// In en, this message translates to:
  /// **'They can claim this name when they join.'**
  String get addPlaceholderHelper;

  /// No description provided for @renamePlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Change name'**
  String get renamePlaceholderTitle;

  /// No description provided for @memberNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get memberNameLabel;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @placeholderAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added'**
  String placeholderAdded(String name);

  /// No description provided for @leaveGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroupButton;

  /// No description provided for @leaveGroupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {group}?'**
  String leaveGroupDialogTitle(String group);

  /// No description provided for @leaveGroupDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see this group any more. You can join again with its code.'**
  String get leaveGroupDialogBody;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leaveGroupConfirm;

  /// No description provided for @leaveGroupNotSettled.
  ///
  /// In en, this message translates to:
  /// **'Settle up first. Your balance here is {amount}.'**
  String leaveGroupNotSettled(String amount);

  /// No description provided for @inviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteTitle;

  /// No description provided for @inviteInstructions.
  ///
  /// In en, this message translates to:
  /// **'Friends install Settle, tap Join with a code, and enter this code or scan the QR.'**
  String get inviteInstructions;

  /// No description provided for @inviteQrLabel.
  ///
  /// In en, this message translates to:
  /// **'QR code for {code}'**
  String inviteQrLabel(String code);

  /// No description provided for @shareOnWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsApp;

  /// No description provided for @copyCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCodeButton;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// WhatsApp invite text (PLAN.md §6)
  ///
  /// In en, this message translates to:
  /// **'Join our group on Settle. Code: {code}. Download: {link}'**
  String inviteMessage(String code, String link);

  /// No description provided for @newCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Get a new code'**
  String get newCodeButton;

  /// No description provided for @newCodeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a new join code?'**
  String get newCodeDialogTitle;

  /// No description provided for @newCodeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The code {code} will stop working. People already in the group stay in it.'**
  String newCodeDialogBody(String code);

  /// No description provided for @newCodeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Get new code'**
  String get newCodeConfirm;

  /// No description provided for @errorOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open WhatsApp.'**
  String get errorOpenWhatsApp;

  /// No description provided for @joinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a group'**
  String get joinTitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Join code'**
  String get joinCodeLabel;

  /// No description provided for @joinCodeHint.
  ///
  /// In en, this message translates to:
  /// **'CHAI-7KQ2M'**
  String get joinCodeHint;

  /// No description provided for @scanQrButton.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQrButton;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @errorCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Codes look like CHAI-7KQ2M.'**
  String get errorCodeFormat;

  /// No description provided for @errorCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No group has this code. It may have been changed.'**
  String get errorCodeNotFound;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanTitle;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at the group\'s QR code.'**
  String get scanHint;

  /// No description provided for @errorCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Settle needs the camera to scan. Allow it in Settings, or type the code.'**
  String get errorCameraDenied;

  /// No description provided for @errorCamera.
  ///
  /// In en, this message translates to:
  /// **'The camera isn\'t available. Type the code instead.'**
  String get errorCamera;

  /// No description provided for @claimTitle.
  ///
  /// In en, this message translates to:
  /// **'Which one are you?'**
  String get claimTitle;

  /// No description provided for @claimBody.
  ///
  /// In en, this message translates to:
  /// **'Pick your name so expenses added for you come with you.'**
  String get claimBody;

  /// No description provided for @claimNotListed.
  ///
  /// In en, this message translates to:
  /// **'I\'m not listed'**
  String get claimNotListed;

  /// No description provided for @claimRejoin.
  ///
  /// In en, this message translates to:
  /// **'Rejoin as {name}'**
  String claimRejoin(String name);

  /// Success SnackBar after joining; Roman Urdu touch
  ///
  /// In en, this message translates to:
  /// **'Khush aamdeed! You\'re in {group}.'**
  String joinedGroup(String group);

  /// No description provided for @overallLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overallLabel;

  /// No description provided for @groupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsLabel;

  /// No description provided for @balanceYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String balanceYouOwe(String amount);

  /// No description provided for @balanceYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed {amount}'**
  String balanceYouAreOwed(String amount);

  /// No description provided for @balanceAllSettled.
  ///
  /// In en, this message translates to:
  /// **'You\'re all settled up'**
  String get balanceAllSettled;

  /// No description provided for @balanceBothLine.
  ///
  /// In en, this message translates to:
  /// **'You owe {owe} · You are owed {owed}'**
  String balanceBothLine(String owe, String owed);

  /// No description provided for @rowSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get rowSettled;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String membersCount(int count);

  /// No description provided for @groupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{type} · {members}'**
  String groupSubtitle(String type, String members);

  /// No description provided for @newGroupOrJoin.
  ///
  /// In en, this message translates to:
  /// **'New group or join'**
  String get newGroupOrJoin;

  /// No description provided for @tabExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get tabExpenses;

  /// No description provided for @tabBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get tabBalances;

  /// No description provided for @tabSettleUp.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get tabSettleUp;

  /// No description provided for @settleEveryoneSettled.
  ///
  /// In en, this message translates to:
  /// **'Hisaab barabar. Everyone is settled up.'**
  String get settleEveryoneSettled;

  /// No description provided for @transferPays.
  ///
  /// In en, this message translates to:
  /// **'{from} pays {to}'**
  String transferPays(String from, String to);

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @nameRow.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameRow;

  /// No description provided for @emailRow.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailRow;

  /// No description provided for @passwordRow.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordRow;

  /// No description provided for @changeNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get changeNameTitle;

  /// No description provided for @nameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Name updated'**
  String get nameUpdated;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get passwordChanged;

  /// No description provided for @errorCurrentPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t your current password.'**
  String get errorCurrentPasswordWrong;

  /// No description provided for @placeholderRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get placeholderRemove;

  /// No description provided for @placeholderRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String placeholderRemoved(String name);

  /// No description provided for @placeholderNotSettled.
  ///
  /// In en, this message translates to:
  /// **'{name} has a balance of {amount}. Settle up before removing them.'**
  String placeholderNotSettled(String name, String amount);

  /// No description provided for @deleteGroupButton.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroupButton;

  /// No description provided for @deleteGroupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {group}?'**
  String deleteGroupDialogTitle(String group);

  /// No description provided for @deleteGroupDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re the only member left. This deletes the group, its expenses and its history. It can\'t be undone.'**
  String get deleteGroupDialogBody;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteGroupConfirm;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'{group} deleted'**
  String groupDeleted(String group);

  /// No description provided for @addExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseTitle;

  /// No description provided for @addExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseButton;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @currencyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get currencyPrefix;

  /// No description provided for @expenseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What was it for?'**
  String get expenseTitleLabel;

  /// No description provided for @expenseTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Chai, dinner, petrol'**
  String get expenseTitleHint;

  /// No description provided for @paidByRow.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidByRow;

  /// No description provided for @splitRow.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitRow;

  /// No description provided for @splitEqually.
  ///
  /// In en, this message translates to:
  /// **'Equally between {count, plural, =1{1 person} other{{count} people}}'**
  String splitEqually(int count);

  /// No description provided for @dateRow.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateRow;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @whoPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get whoPaidTitle;

  /// No description provided for @splitEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} each'**
  String splitEach(String amount);

  /// No description provided for @errorAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount.'**
  String get errorAmountRequired;

  /// No description provided for @errorAmountTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than Rs 1,000,000,000.'**
  String get errorAmountTooLarge;

  /// No description provided for @errorExpenseTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Add what it was for.'**
  String get errorExpenseTitleRequired;

  /// No description provided for @errorPickSomeone.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one person.'**
  String get errorPickSomeone;

  /// No description provided for @expenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Done! Expense add ho gaya'**
  String get expenseAdded;

  /// No description provided for @undoButton.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoButton;

  /// No description provided for @expensePaidBy.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount}'**
  String expensePaidBy(String name, String amount);

  /// No description provided for @expenseYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount}'**
  String expenseYouPaid(String amount);

  /// No description provided for @rowNotInvolved.
  ///
  /// In en, this message translates to:
  /// **'Not involved'**
  String get rowNotInvolved;

  /// No description provided for @rowEven.
  ///
  /// In en, this message translates to:
  /// **'Paid your share'**
  String get rowEven;

  /// No description provided for @pickGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to which group?'**
  String get pickGroupTitle;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @stackYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get stackYouOwe;

  /// No description provided for @stackYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get stackYouAreOwed;

  /// No description provided for @transferYouPay.
  ///
  /// In en, this message translates to:
  /// **'You pay {name}'**
  String transferYouPay(String name);

  /// No description provided for @transferPaysYou.
  ///
  /// In en, this message translates to:
  /// **'{name} pays you'**
  String transferPaysYou(String name);

  /// No description provided for @settleYoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Your payments'**
  String get settleYoursLabel;

  /// No description provided for @settleOthersLabel.
  ///
  /// In en, this message translates to:
  /// **'Others in the group'**
  String get settleOthersLabel;

  /// No description provided for @stackOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get stackOwes;

  /// No description provided for @stackIsOwed.
  ///
  /// In en, this message translates to:
  /// **'Gets back'**
  String get stackIsOwed;

  /// No description provided for @iPaidButton.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get iPaidButton;

  /// No description provided for @recordPaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPaymentButton;

  /// No description provided for @remindButton.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remindButton;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @notReceivedButton.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get notReceivedButton;

  /// No description provided for @cancelPaymentButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment'**
  String get cancelPaymentButton;

  /// No description provided for @payTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay {name}'**
  String payTitle(String name);

  /// No description provided for @recordTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment from {name}'**
  String recordTitle(String name);

  /// No description provided for @balanceYouOweName.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String balanceYouOweName(String name, String amount);

  /// No description provided for @balanceNameOwesYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String balanceNameOwesYou(String name, String amount);

  /// No description provided for @pendingSaysPaidYou.
  ///
  /// In en, this message translates to:
  /// **'{name} says they paid you'**
  String pendingSaysPaidYou(String name);

  /// No description provided for @pendingYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid {name}'**
  String pendingYouPaid(String name);

  /// No description provided for @pendingWaitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm'**
  String pendingWaitingFor(String name);

  /// No description provided for @paymentSentToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sent to {name} to confirm'**
  String paymentSentToConfirm(String name);

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentRecorded;

  /// No description provided for @paymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Payment confirmed'**
  String get paymentConfirmed;

  /// No description provided for @paymentNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Marked as not received'**
  String get paymentNotReceived;

  /// No description provided for @paymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelled;

  /// No description provided for @remindTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind {name}'**
  String remindTitle(String name);

  /// No description provided for @remindMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get remindMessageLabel;

  /// No description provided for @remindSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send on WhatsApp'**
  String get remindSendButton;

  /// No description provided for @remindMessage.
  ///
  /// In en, this message translates to:
  /// **'Salam! {amount} for {group} is pending on Settle.'**
  String remindMessage(String amount, String group);

  /// No description provided for @pendingToConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment to confirm} other{{count} payments to confirm}}'**
  String pendingToConfirm(int count);

  /// No description provided for @paymentRowYouPaid.
  ///
  /// In en, this message translates to:
  /// **'You paid {name}'**
  String paymentRowYouPaid(String name);

  /// No description provided for @paymentRowPaidYou.
  ///
  /// In en, this message translates to:
  /// **'{name} paid you'**
  String paymentRowPaidYou(String name);

  /// No description provided for @paymentRowPaid.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to}'**
  String paymentRowPaid(String from, String to);

  /// No description provided for @paymentRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentRowLabel;

  /// No description provided for @rowSettledExpense.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get rowSettledExpense;

  /// No description provided for @heroYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get heroYouAreOwed;

  /// No description provided for @heroYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get heroYouOwe;

  /// No description provided for @heroYourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get heroYourBalance;

  /// No description provided for @heroAllSettled.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get heroAllSettled;

  /// No description provided for @pendingSaysPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Says they paid {amount}'**
  String pendingSaysPaidAmount(String amount);

  /// No description provided for @pendingWaitingAmount.
  ///
  /// In en, this message translates to:
  /// **'{amount} sent, waiting for {name} to confirm'**
  String pendingWaitingAmount(String name, String amount);

  /// No description provided for @splitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitTitle;

  /// No description provided for @splitTitleAmount.
  ///
  /// In en, this message translates to:
  /// **'Split {amount}'**
  String splitTitleAmount(String amount);

  /// No description provided for @splitModeEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get splitModeEqual;

  /// No description provided for @splitModeExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get splitModeExact;

  /// No description provided for @splitModePercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get splitModePercent;

  /// No description provided for @splitHintEqual.
  ///
  /// In en, this message translates to:
  /// **'Tick who was there.'**
  String get splitHintEqual;

  /// No description provided for @splitHintExact.
  ///
  /// In en, this message translates to:
  /// **'Enter what each person owes.'**
  String get splitHintExact;

  /// No description provided for @splitHintPercent.
  ///
  /// In en, this message translates to:
  /// **'Enter each person\'s percentage.'**
  String get splitHintPercent;

  /// No description provided for @splitLeftToAssign.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to assign'**
  String splitLeftToAssign(String amount);

  /// No description provided for @splitTooMuch.
  ///
  /// In en, this message translates to:
  /// **'{amount} too much'**
  String splitTooMuch(String amount);

  /// No description provided for @splitAddsUp.
  ///
  /// In en, this message translates to:
  /// **'Adds up to {amount}'**
  String splitAddsUp(String amount);

  /// No description provided for @splitAmountFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount first.'**
  String get splitAmountFirst;

  /// No description provided for @splitByExact.
  ///
  /// In en, this message translates to:
  /// **'Exact amounts'**
  String get splitByExact;

  /// No description provided for @splitByPercent.
  ///
  /// In en, this message translates to:
  /// **'By percentage'**
  String get splitByPercent;

  /// No description provided for @splitYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share {amount}'**
  String splitYourShare(String amount);

  /// No description provided for @percentSuffix.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percentSuffix;

  /// No description provided for @payersMore.
  ///
  /// In en, this message translates to:
  /// **'More than one person'**
  String get payersMore;

  /// No description provided for @payersTitleAmount.
  ///
  /// In en, this message translates to:
  /// **'Who paid {amount}?'**
  String payersTitleAmount(String amount);

  /// No description provided for @payersHint.
  ///
  /// In en, this message translates to:
  /// **'Enter what each person paid.'**
  String get payersHint;

  /// No description provided for @paidByTwo.
  ///
  /// In en, this message translates to:
  /// **'{first} and {second}'**
  String paidByTwo(String first, String second);

  /// No description provided for @paidByMany.
  ///
  /// In en, this message translates to:
  /// **'{first} and {count} others'**
  String paidByMany(String first, int count);

  /// No description provided for @expenseManyPaid.
  ///
  /// In en, this message translates to:
  /// **'{count} people paid {amount}'**
  String expenseManyPaid(int count, String amount);

  /// No description provided for @itemsOpen.
  ///
  /// In en, this message translates to:
  /// **'Split a bill by items'**
  String get itemsOpen;

  /// No description provided for @itemsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit items'**
  String get itemsEdit;

  /// No description provided for @itemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Split by items'**
  String get itemsTitle;

  /// No description provided for @itemsSection.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsSection;

  /// No description provided for @itemsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get itemsAdd;

  /// No description provided for @itemAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get itemAddTitle;

  /// No description provided for @itemEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemEditTitle;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemNameLabel;

  /// No description provided for @itemNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Steak'**
  String get itemNameHint;

  /// No description provided for @itemPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get itemPriceLabel;

  /// No description provided for @itemWhoHad.
  ///
  /// In en, this message translates to:
  /// **'Who had it?'**
  String get itemWhoHad;

  /// No description provided for @itemEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get itemEveryone;

  /// No description provided for @itemUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemUnnamed;

  /// No description provided for @itemSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get itemSaveButton;

  /// No description provided for @itemDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get itemDeleteButton;

  /// No description provided for @extrasSection.
  ///
  /// In en, this message translates to:
  /// **'Tax, service and tip'**
  String get extrasSection;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @serviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service charge'**
  String get serviceLabel;

  /// No description provided for @tipLabel.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tipLabel;

  /// No description provided for @whoOwesSection.
  ///
  /// In en, this message translates to:
  /// **'Who owes what'**
  String get whoOwesSection;

  /// No description provided for @billTotal.
  ///
  /// In en, this message translates to:
  /// **'Bill total {amount}'**
  String billTotal(String amount);

  /// No description provided for @billTotalChanges.
  ///
  /// In en, this message translates to:
  /// **'The amount changes from {amount}'**
  String billTotalChanges(String amount);

  /// No description provided for @billAddsUpTo.
  ///
  /// In en, this message translates to:
  /// **'The bill adds up to {amount}'**
  String billAddsUpTo(String amount);

  /// No description provided for @errorItemsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item.'**
  String get errorItemsNeeded;

  /// No description provided for @errorItemNeedsPeople.
  ///
  /// In en, this message translates to:
  /// **'Pick who had each item.'**
  String get errorItemNeedsPeople;

  /// No description provided for @errorPickWhoHad.
  ///
  /// In en, this message translates to:
  /// **'Pick who had it.'**
  String get errorPickWhoHad;

  /// No description provided for @splitByItems.
  ///
  /// In en, this message translates to:
  /// **'By items'**
  String get splitByItems;

  /// No description provided for @unitSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Switch between % and Rs'**
  String get unitSwitchHint;

  /// No description provided for @extrasByOrderNote.
  ///
  /// In en, this message translates to:
  /// **'Tax and service charge are shared by what each person ordered.'**
  String get extrasByOrderNote;

  /// No description provided for @tipGiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Who gives the tip'**
  String get tipGiverLabel;

  /// No description provided for @tipGiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Who gives the tip?'**
  String get tipGiverTitle;

  /// No description provided for @tipEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone, equally'**
  String get tipEveryone;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'0300 1234567'**
  String get phoneHint;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Friends in your groups can remind you on WhatsApp.'**
  String get phoneHelper;

  /// No description provided for @phoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneTitle;

  /// No description provided for @phoneNotAdded.
  ///
  /// In en, this message translates to:
  /// **'Not added'**
  String get phoneNotAdded;

  /// No description provided for @phoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone number saved'**
  String get phoneUpdated;

  /// No description provided for @phoneRemoved.
  ///
  /// In en, this message translates to:
  /// **'Phone number removed'**
  String get phoneRemoved;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a mobile number like 0300 1234567, or +country code.'**
  String get errorInvalidPhone;

  /// No description provided for @remindPickChat.
  ///
  /// In en, this message translates to:
  /// **'They haven\'t added a phone number, so WhatsApp will ask who to send it to.'**
  String get remindPickChat;

  /// No description provided for @remindSendsTo.
  ///
  /// In en, this message translates to:
  /// **'Opens your WhatsApp chat with {phone}.'**
  String remindSendsTo(String phone);

  /// No description provided for @stackYouLent.
  ///
  /// In en, this message translates to:
  /// **'You lent'**
  String get stackYouLent;

  /// No description provided for @editExpenseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpenseTitle;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @deleteExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Delete expense'**
  String get deleteExpenseButton;

  /// No description provided for @restoreExpenseButton.
  ///
  /// In en, this message translates to:
  /// **'Restore expense'**
  String get restoreExpenseButton;

  /// No description provided for @expenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get expenseDeleted;

  /// No description provided for @expenseRestored.
  ///
  /// In en, this message translates to:
  /// **'Expense restored'**
  String get expenseRestored;

  /// Success SnackBar after editing (DESIGN.md §10 Roman Urdu touch).
  ///
  /// In en, this message translates to:
  /// **'Done! Expense update ho gaya'**
  String get expenseUpdated;

  /// No description provided for @detailAddedBy.
  ///
  /// In en, this message translates to:
  /// **'{date} · added by {name}'**
  String detailAddedBy(String date, String name);

  /// No description provided for @detailYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String detailYouOwe(String amount);

  /// No description provided for @detailYouLent.
  ///
  /// In en, this message translates to:
  /// **'You lent {amount}'**
  String detailYouLent(String amount);

  /// No description provided for @detailPaidShare.
  ///
  /// In en, this message translates to:
  /// **'You paid your share'**
  String get detailPaidShare;

  /// No description provided for @detailNotInvolved.
  ///
  /// In en, this message translates to:
  /// **'You\'re not part of this one'**
  String get detailNotInvolved;

  /// No description provided for @detailDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted. It doesn\'t count in balances.'**
  String get detailDeleted;

  /// No description provided for @detailPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get detailPaidBy;

  /// No description provided for @detailSplitEqual.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get detailSplitEqual;

  /// No description provided for @detailSplitExact.
  ///
  /// In en, this message translates to:
  /// **'Split by exact amounts'**
  String get detailSplitExact;

  /// No description provided for @detailSplitPercent.
  ///
  /// In en, this message translates to:
  /// **'Split by percentage'**
  String get detailSplitPercent;

  /// No description provided for @detailSplitItems.
  ///
  /// In en, this message translates to:
  /// **'Split by items'**
  String get detailSplitItems;

  /// No description provided for @detailHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get detailHistory;

  /// No description provided for @expenseNotFound.
  ///
  /// In en, this message translates to:
  /// **'This expense isn\'t here any more.'**
  String get expenseNotFound;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activityTooltip.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTooltip;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has happened here yet.'**
  String get activityEmpty;

  /// No description provided for @activitySomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get activitySomeone;

  /// No description provided for @activityGroupCreated.
  ///
  /// In en, this message translates to:
  /// **'{actor} created the group'**
  String activityGroupCreated(String actor);

  /// No description provided for @activityGroupRenamed.
  ///
  /// In en, this message translates to:
  /// **'{actor} renamed the group to {name}'**
  String activityGroupRenamed(String actor, String name);

  /// No description provided for @activityJoinCodeRegenerated.
  ///
  /// In en, this message translates to:
  /// **'{actor} made a new join code'**
  String activityJoinCodeRegenerated(String actor);

  /// No description provided for @activityPlaceholderAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added {name}'**
  String activityPlaceholderAdded(String actor, String name);

  /// No description provided for @activityMemberRenamed.
  ///
  /// In en, this message translates to:
  /// **'{actor} changed a name to {name}'**
  String activityMemberRenamed(String actor, String name);

  /// No description provided for @activityPlaceholderRemoved.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed {name}'**
  String activityPlaceholderRemoved(String actor, String name);

  /// No description provided for @activityMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'{name} joined'**
  String activityMemberJoined(String name);

  /// No description provided for @activityPlaceholderClaimed.
  ///
  /// In en, this message translates to:
  /// **'{actor} joined as {name}'**
  String activityPlaceholderClaimed(String actor, String name);

  /// No description provided for @activityMemberLeft.
  ///
  /// In en, this message translates to:
  /// **'{name} left'**
  String activityMemberLeft(String name);

  /// No description provided for @activityExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added {title}'**
  String activityExpenseAdded(String actor, String title);

  /// No description provided for @activityExpenseEdited.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited {title}'**
  String activityExpenseEdited(String actor, String title);

  /// No description provided for @activityExpenseDeleted.
  ///
  /// In en, this message translates to:
  /// **'{actor} deleted {title}'**
  String activityExpenseDeleted(String actor, String title);

  /// No description provided for @activityExpenseRestored.
  ///
  /// In en, this message translates to:
  /// **'{actor} restored {title}'**
  String activityExpenseRestored(String actor, String title);

  /// No description provided for @activityPaymentSent.
  ///
  /// In en, this message translates to:
  /// **'{actor} said they sent a payment'**
  String activityPaymentSent(String actor);

  /// No description provided for @activityPaymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded a payment'**
  String activityPaymentRecorded(String actor);

  /// No description provided for @activityPaymentConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed a payment'**
  String activityPaymentConfirmed(String actor);

  /// No description provided for @activityPaymentCancelled.
  ///
  /// In en, this message translates to:
  /// **'{actor} cancelled a payment'**
  String activityPaymentCancelled(String actor);

  /// No description provided for @activityPaymentNotReceived.
  ///
  /// In en, this message translates to:
  /// **'{actor} said a payment was not received'**
  String activityPaymentNotReceived(String actor);

  /// No description provided for @activityPaymentRemoved.
  ///
  /// In en, this message translates to:
  /// **'{actor} removed a payment'**
  String activityPaymentRemoved(String actor);

  /// No description provided for @activityPaymentLine.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to} {amount}'**
  String activityPaymentLine(String from, String to, String amount);

  /// No description provided for @activityAmountChanged.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String activityAmountChanged(String before, String after);

  /// No description provided for @activityDetailsChanged.
  ///
  /// In en, this message translates to:
  /// **'Details changed'**
  String get activityDetailsChanged;

  /// Duplicate guard title (DESIGN.md §10 gentle nudge).
  ///
  /// In en, this message translates to:
  /// **'Kuch bhool to nahi gaye?'**
  String get duplicateTitle;

  /// No description provided for @duplicateBody.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =0{{title}, {amount} with the same people, was added just now.} =1{{title}, {amount} with the same people, was added 1 minute ago.} other{{title}, {amount} with the same people, was added {minutes} minutes ago.}}'**
  String duplicateBody(int minutes, String title, String amount);

  /// No description provided for @duplicateAddAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get duplicateAddAnyway;

  /// No description provided for @homeNoGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get homeNoGroupsTitle;

  /// No description provided for @homeNoGroupsLine.
  ///
  /// In en, this message translates to:
  /// **'Split bills with friends, family or roommates.'**
  String get homeNoGroupsLine;

  /// No description provided for @homeHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get homeHowItWorks;

  /// No description provided for @homeStep1.
  ///
  /// In en, this message translates to:
  /// **'Make a group, or join one with a code from a friend.'**
  String get homeStep1;

  /// No description provided for @homeStep2.
  ///
  /// In en, this message translates to:
  /// **'Add what anyone paid. Settle works out each person\'s share.'**
  String get homeStep2;

  /// No description provided for @homeStep3.
  ///
  /// In en, this message translates to:
  /// **'See who owes whom, then settle up by bank, Raast, JazzCash or cash.'**
  String get homeStep3;

  /// No description provided for @paymentMethodsSection.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethodsSection;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get addPaymentMethod;

  /// No description provided for @paymentMethodsNote.
  ///
  /// In en, this message translates to:
  /// **'People in your groups see these when they pay you.'**
  String get paymentMethodsNote;

  /// No description provided for @addPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Add payment method'**
  String get addPaymentMethodTitle;

  /// No description provided for @editPaymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit payment method'**
  String get editPaymentMethodTitle;

  /// No description provided for @paymentMethodNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get paymentMethodNameLabel;

  /// No description provided for @paymentMethodNameHelper.
  ///
  /// In en, this message translates to:
  /// **'A bank or wallet, e.g. Meezan Bank or Nayapay'**
  String get paymentMethodNameHelper;

  /// Comma-separated suggestion chips. Bank and wallet brand names; keep them as written.
  ///
  /// In en, this message translates to:
  /// **'Raast,Nayapay,Sadapay,JazzCash,Easypaisa,Meezan Bank,HBL,UBL'**
  String get paymentMethodNameSuggestions;

  /// No description provided for @accountTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Account title'**
  String get accountTitleLabel;

  /// No description provided for @accountTitleHelper.
  ///
  /// In en, this message translates to:
  /// **'The name on the account'**
  String get accountTitleHelper;

  /// No description provided for @accountNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Account number, IBAN or Raast ID'**
  String get accountNumberLabel;

  /// No description provided for @deletePaymentMethodButton.
  ///
  /// In en, this message translates to:
  /// **'Delete payment method'**
  String get deletePaymentMethodButton;

  /// No description provided for @paymentMethodSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get paymentMethodSaved;

  /// No description provided for @paymentMethodDeleted.
  ///
  /// In en, this message translates to:
  /// **'Payment method deleted'**
  String get paymentMethodDeleted;

  /// No description provided for @errorPaymentNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name, e.g. Nayapay or Meezan Bank'**
  String get errorPaymentNameRequired;

  /// No description provided for @errorAccountNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the account number, IBAN or Raast ID'**
  String get errorAccountNumberRequired;

  /// No description provided for @payMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s payment methods'**
  String payMethodsLabel(String name);

  /// No description provided for @payNoMethods.
  ///
  /// In en, this message translates to:
  /// **'{name} hasn\'t added a payment method yet. Ask them how to pay.'**
  String payNoMethods(String name);

  /// No description provided for @copyNumberTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy number'**
  String get copyNumberTooltip;

  /// No description provided for @copiedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedTooltip;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
