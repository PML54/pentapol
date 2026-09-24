enum PlayerNameError { length, invalidCharacter, missingLetter }

String normalizePlayerName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

PlayerNameError? validatePlayerName(String value) {
  final normalized = normalizePlayerName(value);
  final length = normalized.runes.length;
  if (length < 3 || length > 20) return PlayerNameError.length;

  final allowed = RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿŒœÆæ0-9 '\-’]+$");
  if (!allowed.hasMatch(normalized)) return PlayerNameError.invalidCharacter;

  final hasLetter = RegExp(r'[A-Za-zÀ-ÖØ-öø-ÿŒœÆæ]');
  if (!hasLetter.hasMatch(normalized)) return PlayerNameError.missingLetter;
  return null;
}
