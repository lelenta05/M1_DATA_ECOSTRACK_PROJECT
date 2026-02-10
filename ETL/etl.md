# ETL (Extract – Transform – Load)

Un **pipeline ETL** est un ensemble de प्रक्रесс permettant de déplacer des données depuis une ou plusieurs sources vers une base de données cible, généralement un **Data Warehouse**.  
Il se compose de trois phases principales : **Extraction, Transformation et Chargement**.

Dans le cadre du projet EcoTrack, la conception de l’ETL a été réalisée à l’aide des langages **Python** et **SQL**.

Avant la mise en place de l’ETL, une étape de **pré-traitement des données** a été effectuée afin de garantir la qualité et la cohérence des données.

---

# Pré-traitement des données

Avant l’exécution du pipeline ETL, plusieurs opérations de nettoyage et de normalisation ont été réalisées pour préparer les données.

### Nettoyage des valeurs textuelles

Une fonction `clean_text` a été développée pour appliquer plusieurs traitements sur les données textuelles :
- suppression des valeurs manquantes ;
- correction et uniformisation de l’encodage ;
- suppression des retours à la ligne et tabulations ;
- suppression des caractères non imprimables ;
- normalisation du format des textes.

### Nettoyage des DataFrames

Une fonction `clean_dataframe` a été mise en place afin de :
- supprimer les lignes vides ;
- supprimer les doublons ;
- garantir la cohérence globale des données.

### Conversion automatique des types

Une fonction supplémentaire a été développée pour :
- détecter automatiquement les types de colonnes ;
- convertir les données dans les formats appropriés (int, float, date, etc.).

Après validation de cette phase de pré-traitement, les données sont considérées comme prêtes pour le pipeline ETL.

---

# Phase 1 : Extract (Extraction)

La phase d’extraction consiste à récupérer les données depuis les différentes sources :
- fichiers CSV ;
- base de données OLTP.

### Nettoyage des noms de colonnes

Une fonction de standardisation des colonnes a été créée pour :
- supprimer les espaces ;
- convertir les noms en minuscules ;
- remplacer ou supprimer les caractères spéciaux ;
- supprimer les points éventuels.

### Chargement en mémoire

Après nettoyage :
- chaque fichier est chargé dans un **DataFrame Pandas** ;
- les DataFrames sont stockés dans une structure de type dictionnaire ;
- la clé correspond au nom du fichier ;
- la valeur correspond au DataFrame contenant les données.

Cette structure constitue le dataset principal utilisé pour la transformation.

---

# Phase 2 : Transformation

La phase de transformation vise à rendre les données conformes au modèle cible (OLTP et OLAP).

Les transformations suivantes ont été appliquées :

### Conversion des dates
Création d’une fonction permettant de convertir automatiquement les colonnes de type texte en format **datetime**.

### Normalisation des valeurs décimales
Création d’une fonction de formatage des nombres décimaux afin d’assurer la compatibilité :
- conversion du format français (ex : 12,3) vers le format standard SQL (12.3).

Ces fonctions ont été appliquées à l’ensemble des fichiers contenant des colonnes de type date ou décimal.

---

# Environnement de chargement des données

Initialement, le projet utilisait **Docker** pour déployer :
- les bases de données ;
- l’outil Adminer pour la visualisation.

Cependant, en raison des contraintes de ressources locales, une migration a été effectuée vers une solution **Database as a Service (DBaaS)**.

### Solution retenue : Neon.tech

La plateforme **Neon.tech** a été choisie pour :
- disposer d’une base PostgreSQL cloud ;
- réduire l’utilisation des ressources locales ;
- faciliter la gestion et le déploiement ;
- permettre le démarrage, l’arrêt et le clonage rapide des bases de données.

---

# Chargement vers la base OLTP

Le chargement des fichiers CSV vers la base OLTP a été automatisé.

### Configuration de chargement
Une variable `config_oltp` a été définie sous forme de dictionnaire :
- clé : nom de la source de données ;
- valeur : nom de la table cible dans la base OLTP.

### Connexion à la base de données
Plusieurs fonctions ont été développées :
- fonction de connexion à la base Neon ;
- fonction d’initialisation du schéma transactionnel ;
- fonction de chargement des données dans les tables du schéma OLTP.

Les données sont chargées dans le schéma **transactions**, qui représente le système opérationnel.

---

# Chargement vers le Data Warehouse (OLAP)

Pour la base OLAP, chaque dimension a été alimentée à l’aide de scripts dédiés.

### Chargement des dimensions
Pour chaque table de dimension :
- un script spécifique a été développé ;
- les données sont extraites depuis la base OLTP ;
- les attributs sont conformes au modèle dimensionnel défini dans le Data Warehouse.

### Chargement de la table de faits

Pour la table de faits principale :
- le chargement a été réalisé principalement en **SQL** ;
- plusieurs jointures avec les dimensions étaient nécessaires ;
- l’utilisation directe de SQL a permis d’optimiser la performance et la complexité des transformations.

Cette approche a permis d’assurer une intégration cohérente entre :
- le système transactionnel (OLTP) ;
- l’entrepôt de données (OLAP).
