 -- creation table partitionée
CREATE TABLE analytics.fait_mesures_partition (
    id bigserial,
    container_sk integer,
    niveau numeric,
    timestamp_mesure timestamp without time zone
)
 PARTITION BY RANGE (timestamp_mesure);

-- creation partitions

CREATE TABLE analytics.fait_mesures_2026_01
PARTITION OF analytics.fait_mesures_partition
FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE analytics.fait_mesures_2026_02
PARTITION OF analytics.fait_mesures_partition
FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');

CREATE TABLE analytics.fait_mesures_2026_03
PARTITION OF analytics.fait_mesures_partition
FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');

CREATE TABLE analytics.fait_mesures_2026_04
PARTITION OF analytics.fait_mesures_partition
FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

CREATE TABLE analytics.fait_mesures_2026_05
PARTITION OF analytics.fait_mesures_partition
FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');

-- migration des donnees
INSERT INTO analytics.fait_mesures_partition (
  container_sk,		
  timestamp_mesure )
SELECT
   container_sk,					
timestamp_mesure 
FROM analytics.fait_mesures_backup;

-- test partition pruning
EXPLAIN
SELECT *
FROM analytics.fait_mesures_partition
WHERE timestamp_mesure >= '2026-02-01'
AND timestamp_mesure < '2026-03-01'; 
-- resultat : seq scan: on fait_mesures_2026_02 as fait_mesures_partition, cost: 25,3
