## 1. Type de partitionnement
# Options possibles

- RANGE
- LIST
- HASH

# Choix optimal : RANGE

Pourquoi ?

- Données temporelles
- Requêtes filtrées par date
- Suppression facile des anciennes données

Partition pruning efficace

Pour des timestamps, RANGE est la meilleure stratégie.

2. Granularité

Tu passes à 10 000 poubelles.

On avait estimé :

10 000 × 96 mesures/jour × 365 jours
≈ 350 millions de lignes/an

Donc :

1 an = 350M lignes

1 mois ≈ 29M lignes

# Analyse

-Partition journalière → trop de partitions
-Partition annuelle → trop grosse
-Partition trimestrielle → ~87M lignes
-Partition mensuelle → ~29M lignes

# Choix recommandé : partition mensuelle

Bon équilibre entre :

-volume
-maintenance
-performance
-politique de rétention

3. Colonne de partition
- timestamp_mesure

Car :

- utilisée dans WHERE
- utilisée pour tri
- utilisée pour analyses temporelles

# Etapes et scripts
## sauvegarde table mesures

--CREATE TABLE analytics.fait_mesures_backup AS
--SELECT * FROM analytics.fait_mesures;

## creation table partitionée
--CREATE TABLE analytics.fait_mesures_partition (
--    id bigserial,
--    container_sk integer,
--    niveau numeric,
--    timestamp_mesure timestamp without time zone
--)
-- PARTITION BY RANGE (timestamp_mesure);

## creation partitions

--CREATE TABLE analytics.fait_mesures_2026_01
--PARTITION OF analytics.fait_mesures_partition
--FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
--
--CREATE TABLE analytics.fait_mesures_2026_02
--PARTITION OF analytics.fait_mesures_partition
--FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

--CREATE TABLE analytics.fait_mesures_2026_03
--PARTITION OF analytics.fait_mesures_partition
--FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
--
--CREATE TABLE analytics.fait_mesures_2026_04
--PARTITION OF analytics.fait_mesures_partition
--FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
--
--CREATE TABLE analytics.fait_mesures_2026_05
--PARTITION OF analytics.fait_mesures_partition
--FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

## migration des donnees
--INSERT INTO analytics.fait_mesures_partition (
--  container_sk,		
--  timestamp_mesure )
--SELECT
--   container_sk,					
--timestamp_mesure 
--FROM analytics.fait_mesures_backup;

## test partition pruning
--EXPLAIN
--SELECT *
--FROM analytics.fait_mesures_partition
--WHERE timestamp_mesure >= '2026-02-01'
--AND timestamp_mesure < '2026-03-01';
## -- resultat : seq scan: on fait_mesures_2026_02 as fait_mesures_partition, cost: 25,3

# Difficultés rencontrées

## Erreur lors de la migration des données

Erreur :
INSERT has more expressions than target columns

Cause :
Structure différente entre :

fait_mesures_backup
table partitionnée

Utilisation de SELECT *

Solution :
- Spécifier explicitement les colonnes dans l’INSERT

- Vérification des structures avec \d

## Gestion du partition pruning

Difficulté :
- Comprendre comment vérifier que PostgreSQL n’analyse qu’une seule partition

Solution :
- Utilisation de EXPLAIN

Recherche de :
- Partitions removed: X

