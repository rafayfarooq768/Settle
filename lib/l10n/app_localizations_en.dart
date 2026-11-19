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
}
