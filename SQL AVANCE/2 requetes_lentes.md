### actvation pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

## verification :
SELECT * FROM pg_extension
WHERE extname = 'pg_stat_statements';

## requete pour connaitre les requetes lentes
SELECT
  query,
  calls,
  total_exec_time,
  mean_exec_time,
  rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

### methode d'analyse d'un requete lente
EXPLAIN ANALYZE
<la requête>;

### Requêtes lentes
## n°1 – Consultation des mesures

SELECT *
FROM fait_mesures
WHERE container_id = 42
ORDER BY created_at DESC
LIMIT 100;

# EXPLAIN ANALYZE (extrait type)

- Seq Scan on fait_mesures  
- Rows: 100 rows 
- Execution Time: 598ms

## n°2 – Jointure dimensions

SELECT *
FROM fait_mesures f
JOIN dim_containers d
ON f.container_id = d.id;

# EXPLAIN ANALYZE (extrait type)

- Seq Scan on fait_mesures  
- Rows: 464ms rows
- Execution Time:544ms


