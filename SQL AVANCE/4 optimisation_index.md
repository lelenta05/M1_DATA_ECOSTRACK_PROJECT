## Quand utiliser un index B-tree ?
# Principe

Le B-tree est l’index par défaut dans PostgreSQL.
Il est basé sur une structure d’arbre équilibré permettant :

- recherches exactes
- comparaisons
- tris
- plages de valeurs

## Cas d’usage recommandés

Clés primaires et clés étrangères

# Recherches d’égalité :

WHERE container_id = 10


# Recherches par intervalle :

WHERE created_at BETWEEN '2025-01-01' AND '2025-01-31'


# ORDER BY et LIMIT :

ORDER BY created_at DESC LIMIT 100

# Avantages
- Polyvalent
- Performant pour la majorité des requêtes
- Supporte les jointures
- Supporte les contraintes UNIQUE

# Limites


## Quand utiliser un index GIN ?
Principe

-GIN = Generalized Inverted Index

-conçu pour données multi-valeurs

-recherche à l’intérieur d’un document

-très utilisé avec JSONB et tableaux

-Cas d’usage

-Colonnes JSONB

-Recherche plein texte

-Tableaux PostgreSQL

-Métadonnées IoT flexibles

## Pourquoi pour ECOTRACK ?

Si une table contient :

metadata JSONB


et des requêtes comme :

WHERE metadata ->> 'type' = 'plastique'


- le B-tree est inefficace
- GIN devient optimal.

## Exemple
CREATE INDEX idx_gin_metadata
ON containers
USING GIN (metadata);

## Avantages

- Recherche rapide dans JSONB

- Support opérateurs @>, ?, ?&

- Parfait pour schéma flexible

## Limites

- Plus coûteux en écriture

- Taille d’index importante

## Quand utiliser un index BRIN ?
Principe

- BRIN = Block Range Index

- indexe des blocs de pages

- pas chaque ligne

- très compact

- Cas idéal

- Tables très volumineuses

- Données naturellement triées

- Séries temporelles

### Exactement le cas de :

fait_mesures(created_at)

Exemple
CREATE INDEX idx_brin_fait_mesures_time
ON fait_mesures
USING BRIN (created_at);

## Avantages

- Taille minuscule

- Création très rapide

- Parfait pour >100M lignes

## Limites

- Moins précis qu’un B-tree

- efficace seulement si données corrélées à l’ordre physique
