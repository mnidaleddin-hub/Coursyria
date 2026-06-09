import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocalizationController extends GetxController {
  final _storage = GetStorage();
  final _localeKey = 'appLocale';

  var currentLocale = const Locale('ar', 'SY').obs;

  @override
  void onInit() {
    super.onInit();
    String? storedLocale = _storage.read(_localeKey);
    if (storedLocale != null) {
      currentLocale.value = Locale(storedLocale);
    }
  }

  void changeLocale(String langCode) {
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
    currentLocale.value = locale;
    _storage.write(_localeKey, langCode);
  }

  /// Feature 182: French terminology helper
  String getFrenchTerm(String term) {
    // Mock dictionary for science terms
    final dictionary = {
      "ميكانيك": "Mécanique",
      "طاقة": "Énergie",
      "خلية": "Cellule",
      "وراثة": "Génétique",
    };
    return dictionary[term] ?? term;
  }
}
