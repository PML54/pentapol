// Modified: 2026-11-12 13:15 — raccorder l’atelier au site Cloudflare Pages publié.
// lib/config/pentapol_website.dart

/// Origine publique vérifiée ; PENTAPOL_WEBSITE_URL permet un aperçu alternatif.
const pentapolWebsiteUrl = String.fromEnvironment(
  'PENTAPOL_WEBSITE_URL',
  defaultValue: 'https://pentapol-site.pages.dev',
);

Uri? cardboardActivityUri(String languageCode) {
  final base = Uri.tryParse(pentapolWebsiteUrl.trim());
  if (base == null ||
      base.scheme != 'https' ||
      base.host.isEmpty ||
      base.userInfo.isNotEmpty ||
      (base.path.isNotEmpty && base.path != '/') ||
      base.hasQuery ||
      base.hasFragment) {
    return null;
  }
  return base.resolve(languageCode == 'fr' ? '/fr/fabriquer/' : '/en/make/');
}
