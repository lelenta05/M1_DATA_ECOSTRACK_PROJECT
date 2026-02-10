## OLTP (Online Transaction Processing)

L’**OLTP (Online Transaction Processing)** désigne les systèmes conçus pour gérer les transactions opérationnelles quotidiennes.  
Ils permettent d’exécuter un grand nombre d’opérations rapides et simultanées telles que les insertions, mises à jour et suppressions de données.

Les systèmes OLTP sont optimisés pour la **gestion des transactions en temps réel** et la cohérence des données.

### Caractéristiques principales

- Écritures fréquentes (INSERT, UPDATE, DELETE)  
- Transactions courtes et rapides  
- Forte cohérence et intégrité des données  
- Accès aux données principalement par clé primaire  
- Données récentes et opérationnelles  
- Modèle de données fortement normalisé (généralement en 3NF)

### Exemples concrets

- Enregistrement d’une mesure envoyée par un capteur  
- Mise à jour de l’état d’un conteneur  
- Création d’une tournée de collecte  
- Affectation d’un agent à une zone ou à une tournée
