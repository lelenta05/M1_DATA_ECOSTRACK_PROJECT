## Différence entre JSON et JSONB

PostgreSQL supporte deux types :

 JSON
 JSONB

# JSON

- Stocké en texte brut
- Reparsée à chaque lecture
- Non indexable efficacement
- Conserve l’ordre des clés
- Conserve les doublons

# JSONB

- Stocké en format binaire
- Compressé
- Clés triées automatiquement
- Doublons supprimés
- Totalement indexable (GIN)
- Optimisé pour les requêtes

## JSONB est plus rapide 
Car :

- Pas besoin de parser du texte à chaque requête
- Accès direct aux clés en format binaire
- Compatible avec index GIN
- Meilleur pour filtres et recherches partielles

# Conclusion : JSONB est le choix optimal pour les métadonnées IoT.

## Indexation JSONB
Quel index utiliser ?

GIN (Generalized Inverted Index)

Pourquoi :

- Parfait pour recherche clé/valeur
- Optimisé pour @>
- Accélère les requêtes sur JSONB

## requetes sql implentées
--ALTER TABLE analytics.dim_containers
--ADD COLUMN metadata JSONB;

# Insertion avec JSON littéral
--UPDATE analytics.dim_containers
--SET metadata = '{
--  "firmware_version": "1.2.3",
--  "battery_level": 87,
--  "sensor_type": "ultrasonic",
--  "connectivity": "LTE"
--}'
--WHERE container_sk = 1;
--# Avec json_build_object()
--UPDATE analytics.dim_containers
--SET metadata = jsonb_build_object(
--    'firmware_version', '1.2.4',
--    'battery_level', 92,
--    'temperature_sensor', true
--)
--WHERE container_sk = 2;

# Lire une clé
--SELECT metadata->'firmware_version'
--FROM analytics.dim_containers;
# Lire en texte
--SELECT metadata->>'firmware_version'
--FROM analytics.dim_containers;
# Filtrer sur une valeur
--SELECT *
--FROM analytics.dim_containers
--WHERE metadata->>'connectivity' = 'LTE';
# Vérifier si contient une structure
--SELECT *
--FROM analytics.dim_containers
--WHERE metadata @> '{"sensor_type":"ultrasonic"}';
# Vérifier si clé existe
--SELECT *
--FROM analytics.dim_containers

# Créer un index GIN global
--CREATE INDEX idx_dim_containers_metadata
--ON analytics.dim_containers
# Indexer un champ spécifique
--CREATE INDEX idx_dim_containers_battery
--ON analytics.dim_containers ((metadata->>'battery_level'));
- Ici index B-tree sur expression.
# Validation performance
# Avant index
--EXPLAIN ANALYZE
--SELECT *
--FROM analytics.dim_containers
--WHERE metadata @> '{"sensor_type":"ultrasonic"}';
# resultat:331ms/ 
- bitmap heap; scan on dim_containers; cost; 32,7 / 
- bitmap index; scan unsing idx_dim_containers_metadata; cost: 12,2

# Comparaison SQL classique vs JSONB
SQL classique	JSONB
Schéma rigide	Flexible
ALTER TABLE fréquent	Non
Index B-tree simple	GIN puissant
Bon pour données fixes	Idéal IoT

## Conclusion

Le type JSONB permet :

- flexibilité des métadonnées IoT
- performance grâce aux index GIN
- évolution rapide du modèle sans refonte

Il est particulièrement adapté à une architecture moderne orientée capteurs et données semi-structurées