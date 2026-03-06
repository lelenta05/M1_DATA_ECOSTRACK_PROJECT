-- requetes sql implentées
ALTER TABLE analytics.dim_containers
ADD COLUMN metadata JSONB;

-- Insertion avec JSON littéral
UPDATE analytics.dim_containers
SET metadata = '{
  "firmware_version": "1.2.3",
  "battery_level": 87,
  "sensor_type": "ultrasonic",
  "connectivity": "LTE"
}'
WHERE container_sk = 1;

-- Avec json_build_object()

UPDATE analytics.dim_containers
SET metadata = jsonb_build_object(
    'firmware_version', '1.2.4',
    'battery_level', 92,
    'temperature_sensor', true
)
WHERE container_sk = 2;
--Lire une clé

SELECT metadata->'firmware_version'
FROM analytics.dim_containers;

--Lire en texte

SELECT metadata->>'firmware_version'
FROM analytics.dim_containers;

-- Filtrer sur une valeur

SELECT *
FROM analytics.dim_containers
WHERE metadata->>'connectivity' = 'LTE';

-- Vérifier si contient une structure

SELECT *
FROM analytics.dim_containers
WHERE metadata @> '{"sensor_type":"ultrasonic"}';

-- Vérifier si clé existe

SELECT *
FROM analytics.dim_containers

-- Créer un index GIN global

CREATE INDEX idx_dim_containers_metadata
ON analytics.dim_containers

-- Indexer un champ spécifique

CREATE INDEX idx_dim_containers_battery
ON analytics.dim_containers ((metadata->>'battery_level'));

--Ici index B-tree sur expression.
