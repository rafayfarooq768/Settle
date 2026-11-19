import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/auth_repository.dart';

String authFailureMessage(BuildContext context, AuthFailure failure) {
  final l10n = AppLocalizations.of(context)!;
  switch (failure) {
    case AuthFailure.invalidEmail:
      return l10n.errorInvalidEmail;
    case AuthFailure.weakPassword:
      return l10n.errorWeakPassword;
    case AuthFailure.wrongPassword:
      return l10n.errorWrongPassword;
    case AuthFailure.userNotFound:
      return l10n.errorUserNotFound;
    case AuthFailure.emailInUse:
      return l10n.errorEmailInUse;
    case AuthFailure.network:
      return l10n.errorNetwork;
    case AuthFailure.cancelled:
      return '';
    case AuthFailure.generic:
      return l10n.errorGeneric;
  }
}
