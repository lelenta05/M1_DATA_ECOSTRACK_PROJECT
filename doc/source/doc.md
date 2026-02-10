# Gestion des sources de données — Projet EcoTrack

Dans le cadre du projet **EcoTrack**, les données ont été générées à l’aide du langage **Python** afin de simuler un environnement réel d’exploitation.

La génération des données suit une **distribution normale (loi normale)** permettant d’obtenir des valeurs cohérentes et réalistes, garantissant ainsi la fiabilité des jeux de données utilisés pour les analyses et les tests.

## Sources de données

Le projet s’appuie sur **17 fichiers CSV** représentant le schéma **OLTP (Online Transaction Processing)**.  
Ces fichiers contiennent les données applicatives qui seront utilisées par la plateforme développée par les équipes techniques.

Ils simulent les données issues du système opérationnel, notamment :
- les mesures des capteurs ;
- les informations sur les conteneurs ;
- les agents ;
- les tournées ;
- les zones ;
- les véhicules ;
- et les autres entités métiers.

## Architecture des flux de données

Deux principales sources alimentent le système analytique :

1. **Fichiers CSV générés**
   - Représentent les données du système transactionnel (OLTP) ;
   - Utilisés pour initialiser et tester la plateforme.

2. **Base de données OLTP**
   - Contient les données opérationnelles de l’application ;
   - Sert de source principale pour l’alimentation du système analytique.

Ces différentes sources alimentent ensuite la **base de données OLAP (Data Warehouse)**, qui sera utilisée pour :
- l’analyse décisionnelle ;
- la création de tableaux de bord ;
- la génération d’indicateurs ;
- les fonctionnalités analytiques avancées ;
- et les futurs modules de machine learning et de prévision.
