# Atelier carton Pentapol

Site statique bilingue publié sur https://pentapol-site.pages.dev le 12 novembre 2026, après accord de Paul. Les pages, images et PDF prêts
à déployer sont dans `public/`. Aucun service serveur ni compilation web requis.

## Routes et fichiers stables

- `/` permet de choisir la langue et pourra accueillir la présentation générale.
- `/fr/fabriquer/` et `/en/make/` présentent l’activité.
- `/downloads/pentapol-cardboard-fr.pdf` et `/downloads/pentapol-cardboard-en.pdf`
  sont les modèles. Conserver ces chemins lors des mises à jour.
- `_headers` demande la revalidation des PDF pour servir les versions mises à jour.

## Régénération

Depuis la racine du dépôt, avec Python et les paquets `reportlab`, `Pillow` et `PyMuPDF` :

```sh
python3 site/tools/build.py
```

Le générateur réutilise les textes des ARB, les numéros de `pentominos.dart` et
la palette classique de `app_settings.dart`, y compris son indexation réelle.
Il vérifie les douze formes distinctes, leur géométrie par rotations/réflexions,
la solution du défi 8/2/6, le format A4 et les limites des textes du PDF.
Les carrés mesurent 20 mm. Vérifier visuellement les PDF après régénération.

## Aperçu local

```sh
python3 -m http.server 8765 --bind 127.0.0.1 --directory site/public
```

Ouvrir le chemin français ou anglais sur le serveur local. L’aperçu est accessible
sur l’ordinateur qui exécute cette commande.

## Déploiement Cloudflare Pages

La configuration est `site/wrangler.toml`. Le projet `pentapol-site` existe, avec
`main` comme branche de production. Déploiement initial `e1bd0dc7`.
Wrangler est déjà installé dans `server/node_modules`.

Depuis `site/`, pour publier une version validée :

```sh
../server/node_modules/.bin/wrangler pages deploy public --project-name pentapol-site --branch main
```

Ces commandes utilisent Direct Upload. Une future intégration Git automatique
nécessiterait un nouveau projet Pages. La publication initiale a été approuvée par Paul dans la conversation.

## Raccordement à l’application

`lib/config/pentapol_website.dart` utilise par défaut l’origine publique vérifiée
`https://pentapol-site.pages.dev`. Les compilations ordinaires activent donc
le téléchargement. `PENTAPOL_WEBSITE_URL` permet de remplacer cette origine
pour un aperçu. La locale effective de l’application choisit la page FR ou EN.

## Contrôles réalisés le 12 novembre 2026

- 350 tests Flutter réussis avec la configuration de production encore vide.
- 4 tests ciblés réussis avec une origine de test locale HTTPS, ouverture simulée,
  erreur puis reprise, FR/EN, petit écran et texte agrandi.
- Analyse sans erreur ni avertissement, 113 informations préexistantes.
- Les deux pages, le sélecteur de langue, les images et les téléchargements
  corrects répondent en HTTP local. Les octets téléchargés correspondent aux PDF.
- Les quatre pages PDF ont été rendues et examinées visuellement.

Après publication : pages FR/EN inspectées dans le navigateur aux formats étroit
et large, sélecteur de langue vérifié. Les liens publics répondent et les PDF
téléchargés ont les mêmes empreintes SHA-256 que les fichiers validés.
Quatre tests ciblés passent également avec l’origine publique par défaut.
La validation du parcours sur un iPhone physique reste à effectuer par Paul.
