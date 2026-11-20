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

  /// No description provided for @homeNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet. Create one or join with a code.'**
  String get homeNoGroups;

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

  /// No description provided for @balanceSettledHere.
  ///
  /// In en, this message translates to:
  /// **'You\'re settled up here'**
  String get balanceSettledHere;

  /// No description provided for @balanceBothLine.
  ///
  /// In en, this message translates to:
  /// **'You owe {owe} · You are owed {owed}'**
  String balanceBothLine(String owe, String owed);

  /// No description provided for @rowYouOwe.
  ///
  /// In en, this message translates to:
  /// **'you owe {amount}'**
  String rowYouOwe(String amount);

  /// No description provided for @rowYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'you are owed {amount}'**
  String rowYouAreOwed(String amount);

  /// No description provided for @rowSettled.
  ///
  /// In en, this message translates to:
  /// **'settled up'**
  String get rowSettled;

  /// No description provided for @memberOwes.
  ///
  /// In en, this message translates to:
  /// **'owes {amount}'**
  String memberOwes(String amount);

  /// No description provided for @memberIsOwed.
  ///
  /// In en, this message translates to:
  /// **'is owed {amount}'**
  String memberIsOwed(String amount);

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

  /// No description provided for @googleOnlyAccount.
  ///
  /// In en, this message translates to:
  /// **'You sign in with Google'**
  String get googleOnlyAccount;

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

  /// No description provided for @whoWasThereTitle.
  ///
  /// In en, this message translates to:
  /// **'Who was there?'**
  String get whoWasThereTitle;

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

  /// No description provided for @rowYouLent.
  ///
  /// In en, this message translates to:
  /// **'you lent {amount}'**
  String rowYouLent(String amount);

  /// No description provided for @rowNotInvolved.
  ///
  /// In en, this message translates to:
  /// **'not involved'**
  String get rowNotInvolved;

  /// No description provided for @rowEven.
  ///
  /// In en, this message translates to:
  /// **'your share is paid'**
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
  /// **'you owe'**
  String get stackYouOwe;

  /// No description provided for @stackYouAreOwed.
  ///
  /// In en, this message translates to:
  /// **'you are owed'**
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
  /// **'owes'**
  String get stackOwes;

  /// No description provided for @stackIsOwed.
  ///
  /// In en, this message translates to:
  /// **'is owed'**
  String get stackIsOwed;
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
