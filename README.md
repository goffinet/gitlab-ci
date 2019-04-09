# Notes sur GitLab CI

<!-- toc -->

Auteur : {{ book.author }}

Date de fabrication : {{ gitbook.time }}

Téléchargements des supports

* [Support en formation PDF](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.pdf)
* [Support en formation EPUB](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.epub)
* [Support en formation MOBI](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.mobi)

## 1. Introduction au projet GitLab

GitLab est un outil de gestion du cycle de vie de DevOps basé Web qui fournit un gestionnaire de référentiel Git fournissant des fonctionnalités wiki, de suivi des problèmes et de pipeline CI/CD. Il est développé sous licence open-source par GitLab Inc.

Le logiciel se décline en quatre produits :

* GitLab CE (Community Edition) - auto-hébergé et grauit, support communautaire.
* GitLab EE (Enterprise Edition) - auto-hébergé et payant, fonctionnalités supplémentaires.
* GitLab.com - SaaS et gratuit.
* GitLab.io - Instance privée gérée par GitLab Inc.

Les outils comparables sont par exemple [GitHub](https://github.com/) ou [Bitbucket](https://bitbucket.org/).

## 2. Introduction à DevOps et à GitLab CI

La documentation de GitLab CI sur trouve à l'adresse [https://docs.gitlab.com/ee/ci/README.html](https://docs.gitlab.com/ee/ci/README.html).

![Stages of the DevOps lifecycle](https://about.gitlab.com/images/stages-devops-lifecycle/devops-loop-and-spans-small.png)

![Stages of the DevOps lifecycle](https://docs.gitlab.com/ee/img/devops-stages.png)

DevOps Stage | Description
--- | ---
[Manage](https://docs.gitlab.com/ee/README.html#manage) | Statistiques et fonctions d'analyse.
[Plan](https://docs.gitlab.com/ee/README.html#plan) | Planification et gestion de projet.
[Create](https://docs.gitlab.com/ee/README.html#create) | Fonctions SCM (Source Code Management)
[Verify](https://docs.gitlab.com/ee/README.html#verify) | Tests, qualité du code et fonctions d'intégration continue.
[Package](https://docs.gitlab.com/ee/README.html#package) | Registre des conteneurs Docker.
[Release](https://docs.gitlab.com/ee/README.html#release) | Release et de livraison de l'application.
[Configure](https://docs.gitlab.com/ee/README.html#configure) | Outils de configuration d'applications et d'infrastructures.
[Monitor](https://docs.gitlab.com/ee/README.html#monitor) | Fonctions de surveillance et de métrique des applications.
[Secure](https://docs.gitlab.com/ee/README.html#secure) | Fonctionnalités de sécurité.


## 3. Projet de départ GitLab CI avec Pages

GitLab Pages est une fonctionnalité qui permet de publier des sites web statiques directement à partir d'un référentiel dans GitLab.

[Creating and Tweaking GitLab CI/CD for GitLab Pages | GitLab](https://docs.gitlab.com/ee/user/project/pages/getting_started_part_four.html)

Un "pipeline" est une suite de "stages", soit un flux d'étapes. Un "stage" exécute des jobs. Ceux-ci sont définit par des variables, des commandes et la génération d'"artifacts". Un "artifacts" est le résultats d'une exécution gardé en mémoire pour traitement dans le "pipeline".

L'exécution des jobs sont réalisées dans des conteneurs Docker sur n'importe quel machine ou Pod K8s (Kubernetes) enregistrés comme "Gitlab Runner".

[GitLab CI/CD Pipeline Configuration Reference](https://docs.gitlab.com/ee/ci/yaml/README.html)

Un "job" spécial nommé "pages" génère tous les "artifacts" d'un site web dans le dossier spécial `public`.

[Job spécial Pages et dossier `public/`](https://docs.gitlab.com/ee/ci/yaml/#pages)

### Essai local avec un exemple Gitlab

Référentiel à importer : [Example GitBook site using GitLab Pages](https://gitlab.com/pages/gitbook.git)


```bash
yum -y install git
```

```bash
git clone https://gitlab.com/pages/gitbook.git
cd gitbook
ls -la
```

```bash
docker run -it -p 4000:4000 -v $PWD:/gitbook node:latest bash
```

```bash
cd /gitbook
npm install gitbook-cli -g
gitbook install
gitbook serve
```

### Pipeline GitLab CI

Fichier .gitlab-ci.yml

```yaml
# requiring the environment of NodeJS 10
image: node:10

# add 'node_modules' to cache for speeding up builds
cache:
  paths:
    - node_modules/ # Node modules and dependencies

before_script:
  - npm install gitbook-cli -g # install gitbook
  - gitbook fetch 3.2.3 # fetch final stable version
  - gitbook install # add any requested plugins in book.json

test:
  stage: test
  script:
    - gitbook build . public # build to public path
  only:
    - branches # this job will affect every branch except 'master'
  except:
    - master

# the 'pages' job will deploy and build your site to the 'public' path
pages:
  stage: deploy
  script:
    - gitbook build . public # build to public path
  artifacts:
    paths:
      - public
    expire_in: 1 week
  only:
    - master # this job will affect only the 'master' branch
```


## 4. CI/CD Gitbook

### Pipeline GitLab CI

Référentiel à importer : [Gitbook Publication](https://github.com/goffinet/gitbook-publication)

![Pipeline Gitlab pour gitbook](/images/pipeline-gitlab-gitbook-publication.jpg)

Fichier `gitlab-ci.yml` :

```yaml
# This pipeline run three stages Test, Build and Deploy
stages:
  - test
  - build
  - deploy

image: goffinet/gitbook:latest

# the 'gitbook' job will test the gitbook tools
gitbook:
  stage: test
  image: registry.gitlab.com/goffinet/gitbook-gitlab:latest
  script:
    - 'echo "node version: $(node -v)"'
    - gitbook -V
    - calibre --version
  allow_failure: false

# the 'lint' job will test the markdown syntax
lint:
  stage: test
  script:
    - 'echo "node version: $(node -v)"'
    - echo "markdownlint version:" $(markdownlint -V)
    - markdownlint --config ./markdownlint.json README.md
    - markdownlint --config ./markdownlint.json *.md
  allow_failure: true

# the 'html' job will build your document in html format
html:
  stage: build
  dependencies:
    - gitbook
    - lint
  script:
    - gitbook install # add any requested plugins in book.json
    - gitbook build . book # html build
  artifacts:
    paths:
      - book
    expire_in: 1 day
  only:
    - master # this job will affect only the 'master' branch the 'html' job will build your document in pdf format
  allow_failure: false

# the 'pdf' job will build your document in pdf format
pdf:
  stage: build
  dependencies:
    - gitbook
    - lint
  before_script:
    - mkdir ebooks
  script:
    - gitbook install # add any requested plugins in book.json
    - gitbook pdf . ebooks/${CI_PROJECT_NAME}.pdf # pdf build
  artifacts:
    paths:
      - ebooks/${CI_PROJECT_NAME}.pdf
    expire_in: 1 day
  only:
    - master # this job will affect only the 'master' branch the 'pdf' job will build your document in pdf format

# the 'epub' job will build your document in epub format
epub:
  stage: build
  dependencies:
    - gitbook
    - lint
  before_script:
    - mkdir ebooks
  script:
    - gitbook install # add any requested plugins in book.json
    - gitbook epub . ebooks/${CI_PROJECT_NAME}.epub # epub build
  artifacts:
    paths:
      - ebooks/${CI_PROJECT_NAME}.epub
    expire_in: 1 day
  only:
    - master # this job will affect only the 'master' branch

# the 'mobi' job will build your document in mobi format
mobi:
  stage: build
  dependencies:
    - gitbook
    - lint
  before_script:
    - mkdir ebooks
  script:
    - gitbook install # add any requested plugins in book.json
    - gitbook mobi . ebooks/${CI_PROJECT_NAME}.mobi # mobi build
  artifacts:
    paths:
      - ebooks/${CI_PROJECT_NAME}.mobi
    expire_in: 1 day
  only:
    - master # this job will affect only the 'master' branch

# the 'pages' job will deploy your site to your gitlab pages service
pages:
  stage: deploy
  dependencies:
    - html
    - pdf
    - mobi
    - epub # We want to specify dependencies in an explicit way, to avoid confusion if there are different build jobs
  script:
    - mkdir .public
    - cp -r book/* .public
    - cp -r ebooks/* .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
    - master
```

### Déploiement sur Netlify

[![Deployer sur Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/goffinet/mkdocs-material-boilerplate)

## 5. CI/CD Jekyll

### Pipeline GitLab CI

Référentiel à importer : [Jekyll good-clean-read](https://github.com/goffinet/good-clean-read)

Fichier `gitlab-ci.yml` :

```yaml
image: ruby:2.3

variables:
  JEKYLL_ENV: production
  LC_ALL: C.UTF-8

before_script:
  - bundle install

pages:
  stage: deploy
  script:
  - bundle exec jekyll build -d public
  artifacts:
    paths:
    - public
  only:
  - gitlab
```

## 6. CI/CD Mkdocs

### Pipeline GitLab CI

Référentiel à importer : [mkdocs-material-boilerplate](https://github.com/goffinet/mkdocs-material-boilerplate)

Fichier `gitlab-ci.yml` :

```yaml
image: python:3.6-alpine

before_script:
  - pip install --upgrade pip && pip install -r requirements.txt

pages:
  script:
    - mkdocs build
    - mv site public
  artifacts:
    paths:
    - public
  only:
  - master
```

### Déploiement sur Netlify

[![Deployer sur Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/goffinet/mkdocs-material-boilerplate)

## 7. CI/CD Maven - Apache Tomcat

https://docs.gitlab.com/ee/ci/examples/artifactory_and_gitlab/

### Premier exemple

Exemple CI/CD avec Maven, lecture de l'exemple et application selon le document [Maven in five minutes](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html).

Créer un dépôt sur Gilab et le cloner localement.

Importer une clé SSH.

Image Docker maven.

Pipeline :

- test
- build

#### Essai local

```bash
mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
cd my-app
docker run -it -v $PWD/my-app:/my-app maven bash
exit
```



#### Pipeline GitLab CI

Fichier `.gitlab-ci.yml`

```yaml
image: maven:latest

build:
  stage: build
  script:
  - mvn package
  artifacts:
    paths:
    - target

test:
  stage: test
  script:
  - java -cp target/my-app-1.0-SNAPSHOT.jar com.mycompany.app.App
```

#### Initialisation d'un repo gitlab

```bash
git init
git add *
echo "target" >> .gitignore
git add .gitignore
git remote add origin https://gitlab.com/account/project.git
git push -u origin master
```

### Second exemple

Cette fois ci avec l'archétype Maven "Webapp" et une phase/job "deploy"

- test
- build
- deploy

#### Déploiement sur Tomcat

...

Méthodes | Authentification
--- | ---
SSH et Bash | clé secrète
SCP | clé secrète
Text Manager avec curl | login/mot de passe

#### Variables cachées

...

#### Gitlab Runner

Exécution sur un Gitlab-Runner qui héberge le serveur applicatif.

...

#### Avertissement Slack

...

#### Pipeline GitLab CI

...

## 8. Installation d'un serveur GitLab CE

### Installation par dépôt de paquetage

[How to Install and Configure GitLab CE on CentOS 7](https://www.howtoforge.com/tutorial/how-to-install-and-configure-gitlab-ce-on-centos-7/).

### Modèle AWS CloudFormation

...

## 9. Administration d'un serveur GitLab

...
