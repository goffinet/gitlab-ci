# Notes sur GitLab CI

<!-- toc -->

Auteur : {{ book.author }}

Date de fabrication : {{ gitbook.time }}

## Formats ebooks

* [Support en formation PDF](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.pdf)
* [Support en formation EPUB](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.epub)
* [Support en formation MOBI](https://goffinet.gitlab.io/gitlab-ci/gitlab-ci.mobi)

## 1. Introduction au projet GitLab

## 2. Introduction à DevOps et à GitLab CI

[https://docs.gitlab.com/ee/ci/README.html](https://docs.gitlab.com/ee/ci/README.html)

## 3. Projet de départ

[Creating and Tweaking GitLab CI/CD for GitLab Pages | GitLab](https://docs.gitlab.com/ee/user/project/pages/getting_started_part_four.html)

[Job spécial Pages et dossier public/](https://docs.gitlab.com/ee/ci/yaml/#pages)

[GitLab CI/CD Pipeline Configuration Reference](https://docs.gitlab.com/ee/ci/yaml/README.html)

### Essai local avec un exemple Gitlab

Référentiel à importer : [Example GitBook site using GitLab Pages:](https://gitlab.com/pages/gitbook.git)


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

Fichier `.gitlab-ci.yml`

#### Pipeline GitLab CI

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


### Second exemple

Cette fois ci avec l'archétype Maven "Webapp" et une phase/job "deploy"

- test
- build
- deploy

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
