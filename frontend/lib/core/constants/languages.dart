/// Langues cibles supportees pour la traduction (Étiquette, Photo, Scan).
///
/// Cle : code ISO 639-1. Valeur : nom affiche en francais.
const Map<String, String> supportedLanguages = {
  'fr': 'français',
  'en': 'anglais',
  'es': 'espagnol',
  'de': 'allemand',
  'it': 'italien',
  'pt': 'portugais',
  'nl': 'néerlandais',
  'pl': 'polonais',
  'ru': 'russe',
  'zh': 'chinois',
  'ja': 'japonais',
  'ko': 'coréen',
  'ar': 'arabe',
};

const String defaultLanguage = 'fr';

String languageLabel(String code) {
  final normalized = code.toLowerCase() == 'zh-cn' ? 'zh' : code.toLowerCase();
  return supportedLanguages[normalized] ?? code;
}

/// Nom de langue avec majuscule initiale, pour l'affichage hors phrase (ex. menu deroulant).
String languageDisplayName(String code) {
  final label = languageLabel(code);
  return label.isEmpty ? label : label[0].toUpperCase() + label.substring(1);
}
