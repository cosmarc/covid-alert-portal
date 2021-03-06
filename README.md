[La version française suit.](#portail-de-soins-de-santé-covid)

# COVID Alert Portal

The COVID Alert Portal provides authenticated healthcare providers unique temporary codes which can be shared with COVID-diagnosed individuals. The code enables individuals to upload their random IDs via the mobile app if they choose. No personal information is collected by the app and there is no association between the codes and specific tests. The Portal complements the [Government of Canada COVID Alert app](https://github.com/cds-snc/covid-alert-app).

A healthcare portal is one of the three pieces of the [COVID Shield](https://www.covidshield.app/) open-source reference implementation built by Shopify volunteers. For a high-level view on how the components work together, read through the [COVID Shield Rationale](https://github.com/CovidShield/rationale).

## Technical overview

The COVID Alert Portal is a Django application: it can be run as a python process or using `docker-compose`.

- Running the COVID Alert Portal locally as a python process requires [python3](https://www.python.org/downloads/) and a database, although an SQLite database will be created if no connection string exists.
- Using `docker-compose`, you’ll need [Docker](https://www.docker.com/get-started) installed.

## Setup

### Activating a virtualenv

Install [`pipenv`](https://pypi.org/project/pipenv/).

```sh
# cd into project folder
pipenv --three  # create a new virtualenv
pipenv shell    # activate virtualenv
pipenv install  # install dependencies
```

### Environment variables

Environment variables are used to control app settings, and configuration for utilities and third-party services. Defaults are `''` or `None` unless otherwise specified.

<details>
<summary>Detailed explanation of each environment variable</summary>
<div>

#### App settings

- `DJANGO_ENV` (default: `development`): Turns on [`DEBUG`](https://docs.djangoproject.com/en/3.0/ref/settings/#debug) mode, as well as doesn't require HTTPS to run. For local development, leave this as `development`.

- `DJANGO_SECRET_KEY`: The `SECRET_KEY` in Django is used to provide cryptographic signing, and should be set to a unique, unpredictable value. Django won't start unless this is set. [Read the docs here](https://docs.djangoproject.com/en/3.0/ref/settings/#secret-key).

- `DJANGO_ALLOWED_HOSTS`: A list of strings representing the host/domain names that this Django site can serve. Only needs to be set in prod. [Read the docs here](https://docs.djangoproject.com/en/3.0/ref/settings/#allowed-hosts).

- `SU_DEFAULT_PASSWORD`: Setting to trigger the creation of a default superuser the first time the app is provisioned. If this variable exists, a default superuser will be created at `admin@cds-snc.ca` with this password.

##### database configuration

- `DATABASE_URL`: A string containing the database scheme, host, username, password, and port. The `DATABASE_URL` is parsed by [`dj-django-url`](https://pypi.org/project/dj-database-url/).

#### CovidAlert API settings

- `API_ENDPOINT`: The API endpoint that returns one-time usage codes. If not set, the one-time codes will read as `0000 0000`.

- `API_AUTHORIZATION`: The credentials required to authenticate with the one-time code API. Otherwise the request will return a `401` Forbidden response.

#### Notify configuration

We are using Notify to send user-facing emails (eg, invitation emails and password reset emails), as well as for our OTP SMS codes through an `django-otp-` plugin.

- `OTK_SMS_TEMPLATE_ID_EN` and `OTK_SMS_TEMPLATE_ID_FR` : Template IDs for the English and French versions of the one-time-key SMS notification
  
- `PASSWORD_RESET_EMAIL_TEMPLATE_ID_EN` and `PASSWORD_RESET_EMAIL_TEMPLATE_ID_FR` : Template IDs for the English and French versions of the password reset email

- `INVITATION_EMAIL_TEMPLATE_ID_EN` and `INVITATION_EMAIL_TEMPLATE_ID_FR` : Template IDs for the English and French versions of the user account creation email

- `BACKUP_CODE_ADMIN_EMAIL_TEMPLATE_ID_EN` and `BACKUP_CODE_ADMIN_EMAIL_TEMPLATE_ID_FR` : Template IDs for the English and French versions of the email that staff users send to admins requesting a new backup code.

- `CONFIRMATION_EMAIL_TEMPLATE_ID_EN` and `CONFIRMATION_EMAIL_TEMPLATE_ID_FR` : Template IDs for the English and French versions of the confirmation emails that is sent to new users after successfully signing-up.

#### OTP (2-factor) configuration

We use Notify and django-otp to send 2FA auth codes via SMS.

- `OTP_NOTIFY_ENDPOINT`: Changes the default Notify endpoint used.

- `OTP_NOTIFY_TEMPLATE_ID`: The is the SMS template used and created via the Notify dashboard.

- `OTP_NOTIFY_API_KEY`: The API key used to call Notify

- `OTP_NOTIFY_NO_DELIVERY`: Used in tests, prints the token in the console instead of calling Notify.

- `OTP_NOTIFY_TOKEN_VALIDITY`: Time in seconds before the token expires

[Read the docs here](https://django-otp-notify.readthedocs.io/en/latest/)

#### Contact form and Freshdesk

The contact form sends any inquiry to Freshdesk.

- `FRESHDESK_API_KEY`: Your user API key generated in Freshdesk.

- `FRESHDESK_API_ENDPOINT`: Your Freshdesk domain with `/api/v2/` at the end.

- `FRESHDESK_PRODUCT_ID`: If you use more than one product, use this variable to specify where the feedback should go to.

##### email configuration

- We use [GC Notify](https://notification.canada.ca/) for sending all user-facing emails and text messages, so we shouldn't need [the SMTP interface that Django provides](https://docs.djangoproject.com/en/3.1/topics/email/). In case there are any errant `send_mail` calls, they will be printed to the console.

#### New Relic configuration

We use New Relic to monitor for server side errors and application performance in production and staging. We do not leverage New Relic client (browser side) metric reporting.

- `NEW_RELIC_APP_NAME`: The app name set up in New Relic.

- `NEW_RELIC_LICENSE_KEY`: Credentials needed to authenticate with New Relic.

</div>
</details>

<strong>[Example `.env` file](https://github.com/cds-snc/covid-healthcare-portal/blob/main/portal/.env.example)</strong>

### Running the app for the first time

**Quick Start:** After activating a virtual environment, run

- `pipenv run css`
- `python manage.py collectstatic --noinput -i scss`
- the `entrypoint.sh` script to perform the database migrations

The local server can be accessed at `http://127.0.0.1:8000/` or `http://localhost:8000`.

For a more thorough setup of the various environment options please follow the instructions below after having activated your virtual environment from inside the root project folder.

Copy `./portal/.env.example` to `./portal/.env` and provide the appropriate values for your configuration.

#### 1. Database migrations

By default the Django creates an SQLite database, but we use Postgres in production.

If a `DATABASE_URL` environment variable exists, it will set all the connection parameters at the same time.

##### Postgres [URL schema](https://github.com/jacobian/dj-database-url#url-schema)

| Django Backend                  | DATABASE_URL                              |
| ------------------------------- | ----------------------------------------- |
| `django.db.backends.postgresql` | `postgres://USER:PASSWORD@HOST:PORT/NAME` |

To create the database schema, run `python manage.py makemigrations`.

Then, create the tables by running `python manage.py migrate`.

#### 2. Compile SCSS files to CSS

You will need to generate the `profiles/static/css/styles.css` file by compiling the SCSS files. To generate the file once, run:

```
pipenv run css
```

If you are developing the app and want your styling changes applied as you make changes, you can use the `--watch` flag.

```
pipenv run csswatch
```

Note that watching the SCSS will require a new terminal window to run the development server. If you are using iTerm, you can open another tab with `Command + t` or a new pane with `Command + d`. Remember to activate your virtual environment in your new pane using `pipenv shell` and `pipenv install`.

#### 3. Create admin super user (optional)

This app allows you to use the Django admininstration panel (`/admin`) to manage users.

In order to access the `/admin` route, you will need to create a super user account to access the admin.

Run `python manage.py createsuperuser` to create a super user.

#### 4. Run development server

Then, run `python manage.py runserver` to run the app. Go to `http://127.0.0.1:8000/` to see the login page.

### Running using Docker Compose

> [Compose](https://docs.docker.com/compose/) is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application’s services. Then, with a single command, you create and start all the services from your configuration.

You can use Docker Compose to build an application container along with a Postgres database. It will map your local files into a Docker container, spin up a PostgreSQL database, and do CSS compilation and a DB migration. The app runs on port `8000`, the database at port `5432` (u: `user`, p: `password`) and will be served at `http://0.0.0.0:8000`.

Read the step-by-step process at [Django, Docker, and PostgreSQL Tutorial](https://learndjango.com/tutorials/django-docker-and-postgresql-tutorial).

### Run

1. Spin up the app: `docker-compose up`
2. Spin down the app: `Command + c` or `docker-compose down`

### Translations

We're using the default Django translations library to add content in French and English.

Here is a short overview of adding a translated string to the application.

Add your string to a template using the `trans` tag.

```
# profiles/templates/profiles/start.html

<h1>{% trans "Generate code for Exposure Notification app" %}</h1>
```

Run `python manage.py makemessages -l fr` to update the `django.po` translations file inside of `/locale`.

```
# locale/fr/LC_MESSAGES/django.po

#: profiles/templates/profiles/start.html:7
msgid "Generate code for Exposure Notification app"
msgstr "Générer du code pour l'application de notification d'exposition"
```

Run `python manage.py compilemessages` to compile the translations so that Django knows how to use them.

For more complete documentation refer to the [Django Translation](https://docs.djangoproject.com/en/3.0/topics/i18n/translation/#translation) docs.

## Development workflow

### Feature development

Feature development on the Portal follows a [trunk-based development](https://trunkbaseddevelopment.com/) workflow. The `main` branch has the most up-to-date code and is always production-ready. When starting a new feature (or a bugfix, etc.), a new branch is created from the tip of the `main` branch. Once the work is complete, the feature is merged back into `main` via a Pull Request (PR). PRs must pass a series of [automated tests](https://github.com/cds-snc/covid-alert-portal#automated-tests) (unit tests, linting, etc), as well as a manual review by another developer. After the automated tests pass and the PR is approved, the code is merged into `main` and the feature branch is deleted. The `main` branch is protected from direct pushes or force pushes — pull requests are mandatory.

### Application versioning

We keep the version number in a root-level [`VERSION` file](https://github.com/cds-snc/covid-alert-portal/blob/main/VERSION) and the list of changes between versions in the root [`CHANGELOG.md` file](https://github.com/cds-snc/covid-alert-portal/blob/main/CHANGELOG.md). We follow [semantic versioning conventions](https://semver.org/) and for the Changelog file we follow the format suggested by [keepachangelog.com](https://keepachangelog.com/en/1.0.0/).

Not all PRs will update the app version — in fact, most of them don’t. PRs with new features or bug fixes require an update to the Changelog file, under “Unreleased”. When the version is next incremented, all of the unreleased changes are included as part of the version bump. It’s okay if something doesn’t make it into the Changelog when it is merged — `CHANGELOG.md` is a file like any other and can be corrected retroactively.

Note that releasing a change to production **requires** incrementing the `VERSION` file. The Changelog is kept up-to-date by convention, but it is not formally required to be in sync with the version in the VERSION file.

### Automated tests

We are using [GitHub Actions](https://github.com/features/actions) as our CI platform: it runs our automated tests for us and automates our deployments.

Our automated tests include:

- `pipenv run test`: Runs our suite of unit tests (on CI we run them in Python versions 3.6, 3.7, 3.8)
- `pipenv run format --check`: uses the `black` Python formatter to ensure consistency of our code
- `pipenv run lint`: uses `flake8` to ensure Python style guide compliance
- Snyk (SaaS): checks for vulnerable dependencies
- LGTM (SaaS): checks for code smells and insecure coding practices
- `terraform plan`: if the terraform config has been modified, `terraform plan` will return a diff of changes between the current infrastructure and the files in the PR.
- `terraform security-scan`: will flag any unsafe configuration changes

We also have an automated test for code coverage, which will fail if code coverage falls below 80%. We are using the [`coverage`](https://coverage.readthedocs.io/en/coverage-5.3/) library, as recommended by the Django docs. Configuration for `coverage` is found in [`pyproject.toml`](https://github.com/cds-snc/covid-alert-portal/blob/main/pyproject.toml).

- `pipenv run coverage_test`: run the unit tests to generate the report
- `pipenv run coverage_report`: display the report

---

# Portail Alerte COVID

Ce dépôt met en oeuvre un portail de soins de santé qui accompagne l’[application mobile COVID Shield du gouvernement du Canada](https://github.com/cds-snc/covid-shield-mobile). Ce portail fournit des codes temporaires à utilisation unique aux professionnels de la santé authentifiés, et ces codes peuvent être transmis aux personnes ayant un diagnostic de COVID-19. Le code permet aux personnes de téléverser les ID aléatoires de l’application mobile si elles acceptent. Aucune information personnelle n’est recueillie, et aucun lien n’est établi entre les codes et les tests.

Pour plus d’information sur la façon dont tout cela fonctionne, référez-vous au [raisonnement derrière COVID Shield](https://github.com/CovidShield/rationale) (en anglais).

## Configuration

### Activer un virtualenv

Installez [`pipenv`](https://pypi.org/project/pipenv/).

```sh
# cd into project folder
pipenv --three  # create a new virtualenv
pipenv shell    # activate virtualenv
pipenv install  # install dependencies
```

### Exécuter l’appli pour une première fois

**Démarrage rapide:** Après avoir activé un environnement virtuel, exécutez le script `entrypoint.sh` pour effectuer les migrations de base de données, la collecte de fichiers statiques et la compilation des fichiers CSS. Une instance de l'application sera alors démarré et sera accessible à `http://127.0.0.1:8000 /` ou `http://localhost:8000`.

Pour une configuration plus approfondie des différentes options d'environnement, veuillez suivre les instructions ci-dessous après avoir activé votre environnement virtuel et déplacé dans le dossier `portal` de niveau supérieur.

Copiez `./portal/.env.example` vers `./portal/.env` et fournissez les valeurs adéquates pour votre configuration.

#### 1. Migrations de bases de données

Par défaut, Django crée une base de données SQLite, mais nous utilisons Postgres en production.

Si une variable d’environnement `DATABASE_URL` existe, elle configurera tous les paramètres de connexion au même moment.

##### Postgres [URL schema](https://github.com/jacobian/dj-database-url#url-schema)

| Django Backend                  | DATABASE_URL                              |
| ------------------------------- | ----------------------------------------- |
| `django.db.backends.postgresql` | `postgres://USER:PASSWORD@HOST:PORT/NAME` |

Pour créer le schéma de base de données, exécutez `python manage.py makemigrations`

Ensuite, créez les tableaux en exécutant `python manage.py migrate`

#### 2. Compilation des fichiers SCSS en CSS

Vous devrez générer le fichier `profiles/static/css/styles.css` en compilant les fichiers SCSS. Pour générer le fichier une seule fois, exécutez :

```
python manage.py sass profiles/static/scss/ profiles/static/css/
```

Si vous développez l’application et que vous voulez voir vos changements de styles être appliqués au fur et à mesure que vous les faites, vous pouvez utiliser le flag `--watch`.

```
python manage.py sass profiles/static/scss/ profiles/static/css/ --watch
```

Remarquez que surveiller ainsi le SCSS nécessitera d’avoir une nouvelle fenêtre du terminal pour exécuter le serveur de développement. Si vous utilisez iTerm, vous pouvez ouvrir un nouvel onglet avec `Command + t` ou ajouter une subdivision avec `Command + d`. N’oubliez pas d’activer votre environnement virtuel dans votre nouvelle subdivision à l’aide de `pipenv shell` et `pipenv install`.

#### 3. Création d’un super utilisateur admin (facultatif)

Cette application vous permet d’utiliser l’admin (`/admin`) pour gérer les utilisateurs, même si les utilisateurs peuvent s’inscrire eux-mêmes.

Pour accéder au chemin `/admin` vous devrez créer un compte de super utilisateur.

Exécutez `python manage.py createsuperuser` pour créer un super utilisateur.

#### 4. Exécution du serveur de développement

Exécutez ensuite `python manage.py runserver` pour faire fonctionner l’application. Rendez-vous à `http://127.0.0.1:8000/` pour voir la page d’accueil.

### Exécuter avec Docker Compose

> [Compose](https://docs.docker.com/compose/) est un outil pour définir et exécuter des applications Docker multiconteneurs. Avec Compose, vous utilisez un fichier YAML pour configurer les services de votre application. Puis, avec une seule commande, vous créez et lancez tous les services à partir de votre configuration.

Vous pouvez utiliser Docker Compose pour construire un conteneur d’application parallèlement à une base de données Postgres. Il va mapper vos fichiers locaux dans un conteneur Docker, créer une base de données PostgreSQL et faire une compilation CSS et une migration de base de données. L’application s’exécute sur le port `8000`, la base de donnée sur le port `5432` (u: `user`, p: `password`) et sera desservie à l’adresse `http://0.0.0.0:8000`.

Vous pouvez les le processus étape par étape sur [Django, Docker, et PostgreSQL Tutorial](https://learndjango.com/tutorials/django-docker-and-postgresql-tutorial) (en anglais).

### Exécuter

1. Créez l’application : `docker-compose up`
2. Arrêter l’exécution de l’application : `Command + c` ou `docker-compose down`

### Traductions

Nous utilisons la bibliothèque Django par défaut pour ajouter de contenu en anglais et en français.

Voici un survol rapide de la façon d’ajouter des chaînes de caractères traduites dans l’application.

Ajoutez votre chaîne de caractères à un modèle en utilisant le tag `trans`.

```
# profiles/templates/profiles/start.html

<h1>{% trans "Generate code for Exposure Notification app" %}</h1>
```

Exécutez `python manage.py makemessages -l fr` pour mettre à jour le fichier de traductions `django.po` à l’intérieur de `/locale`.

```
# locale/fr/LC_MESSAGES/django.po

#: profiles/templates/profiles/start.html:7
msgid "Generate code for Exposure Notification app"
msgstr "Générer du code pour l'application de notification d'exposition"
```

Exécutez `python manage.py compilemessages` pour compiler les traductions afin que Django sache comment les utiliser.

Pour obtenir de la documentation plus exhaustive, veuillez vous référer à celle des [traductions Django](https://docs.djangoproject.com/en/3.0/topics/i18n/translation/#translation) (en anglais).
