# ECOSTRACK_DATAWAREHOUSE
# PARTIE DOCKER POUR L'OBTENTION DE LA DATAWAREHOUSE 

1-Verification de la structure et Demarrage du conteneur 
```bash
ls -la sql/data/
docker-compose up -d 
docker-compose ps 
```
2-Connexion au datawarehouse: 
Dans docker desktop , on ouvre le lien du conteneur ecotrack_adminer et on entre les informations demandées telles que (le nom du service,le nom du datawrehouse,nom de l'utilisateur et le mot de passe).
Ces informations sont dans le fichier docker-compose.yml


3-integration des donnees dans adminer:
etape 1: copier chemin d'acces du fichier csv dans le dossier du conteneur
```bash
docker cp "chemin vers le dossier\OLTP CSV\badges.csv" ecotrack_oltp:/var/lib/postgresql/data/badges.csv
COPY badges(id_badge, code_badge, name, description)
FROM '/var/lib/postgresql/data/badges.csv'
WITH (FORMAT CSV, HEADER TRUE);
```
4-correction direct dans Adminer du nombre de caractere "table vehicules" :
```bash
CREATE TABLE IF NOT EXISTS VEHICULES (
    id_vehicule INTEGER  PRIMARY KEY,
    registration_number VARCHAR(20) NOT NULL ,--numero d'immatriculation 
    model VARCHAR(20) NOT NULL ,
    capacite DECIMAL(5,2) NOT NULL , -- modification nombre caractere :(10,2)
    consommation_moyenne DECIMAL(5,2) NOT NULL ,
    emission_co2_km DECIMAL(5,2) NOT NULL --modfication nombre de caractere :(6,2)
    );
    ```