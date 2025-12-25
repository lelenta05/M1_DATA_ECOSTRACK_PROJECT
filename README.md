# ECOSTRACK_DATAWAREHOUSE
# PARTIE DOCKER POUR L'OBTENTION DE LA DATAWAREHOUSE 
1-Configuration des variables d'environnement 
```bash
cp .env.example .env
```
2-Verification de la structure et Demarrage du conteneur 
```bash
ls -la sql/data/
docker-compose up -d 
docker-compose ps 
```
3-Connexion a la base
-host : localhost
Le reste des informations se trouvent dans le fichier .env (question de sécurite).


