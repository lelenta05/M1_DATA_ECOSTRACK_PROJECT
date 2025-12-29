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



