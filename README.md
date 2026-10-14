# LearnSpace — Plateforme d'apprentissage mobile (v2)

Flutter (mobile) + PHP (API REST, JWT) + MySQL. Deux rôles : **étudiant** et **administrateur**.

```
LearnSpace/
├── backend/     API PHP (index.php, helpers.php, config.php)
├── database/    database.sql (installation neuve) + upgrade.sql (mise à jour v1 -> v2)
└── mobile/      Application Flutter
```

## Compte administrateur par défaut
`admin@learnspace.com` / `admin123`  → **à changer** dès la première connexion (Profil → Changer le mot de passe).

## Fonctionnalités
**Étudiant** : recherche et filtre par catégorie, inscription / désinscription, progression par cours,
bouton « Continuer », profil modifiable (nom, mot de passe), thème clair/sombre automatique.

**Administrateur** :
- Tableau de bord (nombre d'étudiants, cours, leçons, inscriptions, cours les plus suivis, derniers inscrits)
- Cours : créer, modifier, publier / mettre en brouillon, supprimer, choisir une couleur
- Leçons : ajouter, modifier, supprimer, réordonner par glisser-déposer
- Utilisateurs : créer, rechercher, voir la progression, inscrire / désinscrire d'un cours,
  promouvoir ou rétrograder administrateur, supprimer

## Installation
### 1. Base de données
Installation neuve :
```bash
mysql -u root -p < database/database.sql
```
Si vous avez déjà la v1 (avec des utilisateurs à conserver) : importez seulement `database/upgrade.sql`.

### 2. Backend
```bash
cd backend
php -S 0.0.0.0:8000 index.php
```

### 3. Application
```bash
cd mobile
flutter create . --project-name learnspace
flutter pub get
flutter run
```
Réglez l'IP dans `mobile/lib/config.dart` et ajoutez `android:usesCleartextTraffic="true"`
dans `android/app/src/main/AndroidManifest.xml` (balise `<application>`).

## API
Routes étudiant (JWT requis sauf register/login) :
`POST /register`, `POST /login`, `GET|PUT /me`, `GET /courses`, `GET /courses/{id}`,
`POST|DELETE /courses/{id}/enroll`, `POST /lessons/{id}/complete`

Routes administrateur (rôle admin requis, sinon 403) :
`GET /admin/stats`, `GET|POST /admin/courses`, `GET|PUT|DELETE /admin/courses/{id}`,
`POST /admin/courses/{id}/lessons`, `POST /admin/courses/{id}/reorder`, `PUT|DELETE /admin/lessons/{id}`,
`GET|POST /admin/students`, `GET|DELETE /admin/students/{id}`, `POST /admin/students/{id}/role`,
`POST /admin/students/{id}/enroll`, `DELETE /admin/students/{id}/courses/{courseId}`
