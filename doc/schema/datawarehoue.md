# Data Warehouse

## Définitions de base

Un **Data Warehouse** (entrepôt de données), également appelé système **OLAP (Online Analytical Processing)**, est une architecture conçue pour **collecter, centraliser et analyser** des données provenant de sources multiples et hétérogènes (bases de données, fichiers, capteurs IoT, APIs, etc.).

Son objectif principal est de permettre l’**analyse décisionnelle** afin de produire des informations exploitables pour l’entreprise.  
Il facilite ainsi la prise de décision stratégique grâce à des données consolidées, historisées et structurées pour l’analyse.

---

# Modèle de données dimensionnel

## Définition

Un **modèle de données dimensionnel** est une méthode d’organisation et de structuration des données dans un entrepôt de données afin de faciliter leur analyse.

Ce type de modélisation est particulièrement adapté :
- aux **gros volumes de données** ;
- aux besoins d’analyse multidimensionnelle ;
- à l’exploration des données selon plusieurs axes (temps, zone, produit, etc.).

Il permet aux utilisateurs d’obtenir rapidement des indicateurs et des analyses pertinentes pour la prise de décision.

## Types de modélisation de données

Il existe principalement deux approches de modélisation :

1. **Modèle Entité-Relation (ER) normalisé**  
   Utilisé dans les bases de données transactionnelles (OLTP).

2. **Modélisation dimensionnelle (Kimball)**  
   Utilisée dans les entrepôts de données pour l’analyse (OLAP).

Dans le cadre de ce projet, nous utilisons **la modélisation dimensionnelle**, plus adaptée à l’analyse décisionnelle.

## Modélisation dimensionnelle (Approche Kimball)

La modélisation dimensionnelle repose sur des structures **dénormalisées** conçues pour faciliter l’analyse des données.

Elle s’appuie sur :
- des **tables de faits** : contenant les mesures quantitatives ;
- des **tables de dimensions** : contenant les informations descriptives.

Ces structures permettent de conserver un **historique des données** et d’optimiser les performances des requêtes analytiques.

---

# Conception de l’architecture du Data Warehouse

## Étape 1 : Identification des processus métiers

### Processus métier principal
**Suivi et mesure des conteneurs à déchets urbains**

### Objectifs du processus
- Collecter et analyser les données de remplissage des conteneurs ;
- Suivre en temps réel l’état des conteneurs via des capteurs IoT ;
- Fournir des données analytiques pour optimiser les tournées de collecte.

### Activités métiers identifiées
- Mesure du niveau de remplissage des conteneurs ;
- Surveillance des paramètres (température, volume, poids estimé, etc.) ;
- Suivi temporel des mesures ;
- Gestion des conteneurs avec historisation (**SCD Type 2**) ;
- Analyse par zone géographique ;
- Suivi par type de déchet ;
- Monitoring par agent responsable et par équipe de collecte.

### Résultat attendu
Mettre en place un système permettant la **collecte, le stockage et l’analyse** des données relatives aux conteneurs à déchets urbains, contextualisées par différentes dimensions (temps, conteneur, type de déchet, zone, agent), afin d’optimiser les opérations de collecte.

---

## Étape 2 : Identification de la granularité

La **granularité** définit ce que représente une ligne dans la table de faits.  
Elle répond à la question suivante :

> Quelle est la plus petite unité d'information que nous souhaitons analyser ?

Dans ce projet, une ligne de la table de faits correspond à :  
**une mesure enregistrée par un capteur pour un conteneur à un instant donné.**

Cette étape permet d’identifier :
- les mesures à stocker ;
- les dimensions associées ;
- les colonnes nécessaires dans la table de faits.

---

## Étape 3 : Identification des faits et des dimensions

Dans un modèle dimensionnel, on distingue :

### Tables de faits
Les tables de faits contiennent :
- des **mesures numériques** (volume, température, poids, etc.) ;
- des **clés étrangères** vers les dimensions.

Tables de faits du projet :
- **fait_mesures** : table de faits principale (données brutes IoT) ;
- **aggregated_daily_stats** : statistiques agrégées par jour ;
- **ml_predictions** : prédictions issues du modèle de machine learning.

> **Note :** `fait_mesures` constitue la table de faits centrale reliant les données opérationnelles aux données analytiques.

### Tables de dimensions
Les tables de dimensions contiennent les données descriptives permettant l’analyse.

Dimensions identifiées :
- **dim_temps** : analyse temporelle des mesures ;
- **dim_capteurs** : capteurs connectés aux conteneurs qui envoient les valeurs metriques sur l'etat des conteneurs ;
- **dim_conteneur** : informations sur les conteneurs (avec SCD Type 2 pour l’historisation) et capteurs associés ;
- **dim_zone** : informations géographiques ;
- **dim_type_dechet** : type de déchet accepté ;
- **dim_agent** : informations sur les agents et équipes ;
- **dim_tournee** : tournées de collecte ;
- **dim_vehicule** : véhicules utilisés pour les tournées.

---

## Étape 4 : Construction du schéma dimensionnel

Le modèle retenu est un **schéma en étoile (Star Schema)**.

Ce schéma est composé :
- d’une **table de faits centrale** ;
- de plusieurs **tables de dimensions** reliées directement à celle-ci.

### Avantages du schéma en étoile
- simplicité de compréhension ;
- performance des requêtes analytiques ;
- facilité d’utilisation pour la BI et le reporting ;
- optimisation pour les outils OLAP.

> Voir le schéma détaillé : `doc/image/schema/schema_star`
