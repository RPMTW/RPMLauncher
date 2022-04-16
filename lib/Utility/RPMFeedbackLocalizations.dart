import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:rpmlauncher/Utility/I18n.dart';

class RPMFeedbackLocalizations extends FeedbackLocalizations {
  const RPMFeedbackLocalizations();

  @override
  String get submitButtonText => I18n.format('rpmlauncher.feedback.submit');

  @override
  String get feedbackDescriptionText =>
      I18n.format('rpmlauncher.feedback.description');

  @override
  String get draw => I18n.format('rpmlauncher.feedback.draw');

  @override
  String get navigate => I18n.format('rpmlauncher.feedback.navigate');
}

class RPMFeedbackLocalizationsDelegate
    extends LocalizationsDelegate<FeedbackLocalizations> {
  const RPMFeedbackLocalizationsDelegate();

  static const LocalizationsDelegate<FeedbackLocalizations> delegate =
      RPMFeedbackLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<FeedbackLocalizations> load(Locale locale) async {
    return const RPMFeedbackLocalizations();
  }

  @override
  bool shouldReload(RPMFeedbackLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultFeedbackLocalizations.delegate(en_EN)';
}
