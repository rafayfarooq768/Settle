import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'app_localizations.dart';

/// The app's localization delegates. Not the generated
/// `AppLocalizations.localizationsDelegates`: that one still uses the
/// SDK's old Material localizations, which `material_ui` widgets can't
/// find (Flutter 3.47 moved Material into the `material_ui` package).
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
];
