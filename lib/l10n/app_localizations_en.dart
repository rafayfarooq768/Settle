// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Settle';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInEmailLabel => 'Email';

  @override
  String get signInPasswordLabel => 'Password';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signUpPrompt => 'New here?';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpNameLabel => 'Your name';

  @override
  String get signUpNameHelper => 'Friends see this name in groups.';

  @override
  String get signInPrompt => 'Already have an account?';

  @override
  String get orDivider => 'or';

  @override
  String get forgotPasswordButton => 'Forgot password?';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordInstructions =>
      'Enter your account email. We\'ll send you a link to choose a new password.';

  @override
  String get resetPasswordButton => 'Send reset link';

  @override
  String get resetPasswordCheckEmailTitle => 'Check your email';

  @override
  String resetPasswordCheckEmailBody(String email) {
    return 'If an account uses $email, a reset link is on its way. Open it, choose a new password, then come back and sign in.';
  }

  @override
  String get resetPasswordSpamHint =>
      'Not there after a few minutes? Check your spam folder.';

  @override
  String get resetPasswordResend => 'Send again';

  @override
  String get backToSignIn => 'Back to sign in';

  @override
  String get errorNameRequired => 'Enter your name.';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get errorWrongPassword => 'Incorrect email or password.';

  @override
  String get errorUserNotFound => 'No account found with this email.';

  @override
  String get errorEmailInUse => 'An account already exists with this email.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No internet connection. Please try again.';

  @override
  String homeGreeting(String name) {
    return 'Salam, $name';
  }

  @override
  String get signOutButton => 'Sign out';

  @override
  String get homeNoGroups => 'No groups yet. Create one or join with a code.';

  @override
  String get createGroupButton => 'Create group';

  @override
  String get joinWithCodeButton => 'Join with a code';

  @override
  String get moreOptions => 'More options';

  @override
  String get createGroupTitle => 'New group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupTypeLabel => 'Type (optional)';

  @override
  String get groupTypeHelper => 'For example Trip or Home.';

  @override
  String get groupTypeFriends => 'Friends';

  @override
  String get groupTypeTrip => 'Trip';

  @override
  String get groupTypeHome => 'Home';

  @override
  String get groupTypeOffice => 'Office';

  @override
  String get groupTypeFamily => 'Family';

  @override
  String get errorGroupNameRequired => 'Enter a group name.';

  @override
  String get groupCreated => 'Done! Group ban gaya';

  @override
  String get groupSettingsTooltip => 'Group settings';

  @override
  String get groupOnlyYou => 'Add your friends to start splitting.';

  @override
  String get groupNoExpenses => 'Abhi koi expense nahi.';

  @override
  String get inviteFriendsButton => 'Invite friends';

  @override
  String get addByNameButton => 'Add by name';

  @override
  String get groupSettingsTitle => 'Group settings';

  @override
  String get sectionGroup => 'Group';

  @override
  String sectionMembers(int count) {
    return 'Members ($count)';
  }

  @override
  String get sectionInvite => 'Invite';

  @override
  String joinCodeRow(String code) {
    return 'Join code $code';
  }

  @override
  String memberYou(String name) {
    return '$name (you)';
  }

  @override
  String get memberNotJoined => 'not joined yet';

  @override
  String get memberLeft => 'left the group';

  @override
  String get editGroupTitle => 'Edit group';

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get addPlaceholderTitle => 'Add by name';

  @override
  String get addPlaceholderHelper => 'They can claim this name when they join.';

  @override
  String get renamePlaceholderTitle => 'Change name';

  @override
  String get memberNameLabel => 'Name';

  @override
  String get addButton => 'Add';

  @override
  String placeholderAdded(String name) {
    return '$name added';
  }

  @override
  String get leaveGroupButton => 'Leave group';

  @override
  String leaveGroupDialogTitle(String group) {
    return 'Leave $group?';
  }

  @override
  String get leaveGroupDialogBody =>
      'You won\'t see this group any more. You can join again with its code.';

  @override
  String get leaveGroupConfirm => 'Leave';

  @override
  String leaveGroupNotSettled(String amount) {
    return 'Settle up first. Your balance here is $amount.';
  }

  @override
  String get inviteTitle => 'Invite friends';

  @override
  String get inviteInstructions =>
      'Friends install Settle, tap Join with a code, and enter this code or scan the QR.';

  @override
  String inviteQrLabel(String code) {
    return 'QR code for $code';
  }

  @override
  String get shareOnWhatsApp => 'Share on WhatsApp';

  @override
  String get copyCodeButton => 'Copy code';

  @override
  String get codeCopied => 'Code copied';

  @override
  String inviteMessage(String code, String link) {
    return 'Join our group on Settle. Code: $code. Download: $link';
  }

  @override
  String get newCodeButton => 'Get a new code';

  @override
  String get newCodeDialogTitle => 'Get a new join code?';

  @override
  String newCodeDialogBody(String code) {
    return 'The code $code will stop working. People already in the group stay in it.';
  }

  @override
  String get newCodeConfirm => 'Get new code';

  @override
  String get errorOpenWhatsApp => 'Couldn\'t open WhatsApp.';

  @override
  String get joinTitle => 'Join a group';

  @override
  String get joinCodeLabel => 'Join code';

  @override
  String get joinCodeHint => 'CHAI-7KQ2M';

  @override
  String get scanQrButton => 'Scan QR';

  @override
  String get joinButton => 'Join';

  @override
  String get errorCodeFormat => 'Codes look like CHAI-7KQ2M.';

  @override
  String get errorCodeNotFound =>
      'No group has this code. It may have been changed.';

  @override
  String get scanTitle => 'Scan QR';

  @override
  String get scanHint => 'Point the camera at the group\'s QR code.';

  @override
  String get errorCameraDenied =>
      'Settle needs the camera to scan. Allow it in Settings, or type the code.';

  @override
  String get errorCamera =>
      'The camera isn\'t available. Type the code instead.';

  @override
  String get claimTitle => 'Which one are you?';

  @override
  String get claimBody =>
      'Pick your name so expenses added for you come with you.';

  @override
  String get claimNotListed => 'I\'m not listed';

  @override
  String claimRejoin(String name) {
    return 'Rejoin as $name';
  }

  @override
  String joinedGroup(String group) {
    return 'Khush aamdeed! You\'re in $group.';
  }
}
