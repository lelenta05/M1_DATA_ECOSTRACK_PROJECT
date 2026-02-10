# ECOSTRACK_DATAWAREHOUSE

#### Procédure de travail

Pour le projet  :
- Toutes les fonctionnaltés demandées et tests seront réalisés sur **les données d’un mois** (janvier 2024) afin de valider la cohérence et les performances du système.
- Une fois cette étape validée, nous procéderons à :
  - l’**automatisation** du pipeline ETL,
  - l’**extension des critères de qualité et de complétude des données**.

### 1. Verification de la structure et Demarrage du conteneur 
```bash
ls -la sql/data/
docker-compose up -d 
docker-compose ps 
```
### 2. Connexion au datawarehouse: 
Dans docker desktop , on ouvre le lien du conteneur ecotrack_adminer et on entre les informations demandées telles que (le nom du service,le nom du datawrehouse,nom de l'utilisateur et le mot de passe).
Ces informations sont dans le fichier docker-compose.yml
### 3. Avancement du projet

Le projet en est actuellement à la **couche analytique**, utilisant :
- SQL avancé (**postgis**),
- Python avec **Pandas** et **NumPy**,
- Machine Learning avec **Scikit-Learn**.




