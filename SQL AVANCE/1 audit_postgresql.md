# Audit PostgreSQL – ECOTRACK: Audit réalisé depuis l’instance PostgreSQL hébergée sur Neon.


## 1. État des lieux des tables

| Table | Nb lignes (estimé) | Taille data | Taille index | Nb index | PK |

| mesures | 50 | 50.5 MB | 0 MB | 0 | oui |
| dim_mesure_csv |50  | 10.3 MB | 0 MB | 0 | oui |
| spatial_ref_sys | | 7.0 MB | 0.2 MB | 1 | oui |
| dim_tournees | 50 | 4.4 MB | 0.2 MB | ? | oui |
| route_steps |  | 0.7 MB | 0 MB | 0 | oui |

## 2. Observations majeures

### 2.1 Table critique : mesures
- Représente ~75% du volume total
- AUCUN index présent
- Risque élevé de :
  - Seq Scan systématique  
  - latence dashboard  
  - impossibilité de montée à l’échelle

### 2.2 Problèmes identifiés

1. Absence d’index
- Pas d’index sur timestamp
- Pas d’index sur bin_id / équipement
- Pas d’index composite

2. Risques structurels
- Probables tables sans clé primaire
- Types de colonnes inconnus
- Pas de stratégie time-series

3. Impact production
- Requêtes analytiques lentes
- Jointures coûteuses
- Impossible de tenir 350M lignes/an

## 3. Recommandations immédiates

### Index indispensables

CREATE INDEX idx_mesures_time 
ON mesures(created_at DESC);


## Top tables par taille

| Table | Taille totale (bytes) |
|------|-----------------------|
| fait_mesures | 187 940 864 |
| mesures | 50 610 176 |
| mesure_src | 22 323 200 |
| spatial_ref_sys | 7 315 456 |
| dim_tournees | 4 702 208 |
| route_steps | 753 664 |
| collections | 712 704 |
| dim_containers | 376 832 |
| containers | 352 256 |
| dim_capteurs | 344 064 |
| capteurs | 294 912 |
| dim_zones | 212 992 |
| signalements | 106 496 |
| routes | 98 304 |
| zones | 98 304 |
| signalement_treatments | 81 920 |
| dim_temps | 65 536 |
| maintenances | 49 152 |
| dim_type_dechets | 32 768 |
| dim_agents | 32 768 |
| vehicules | 16 384 |
| users | 16 384 |
| users_badges | 16 384 |
| dim_vehicules | 16 384 |
| badges | 16 384 |
| users_roles | 16 384 |
| roles | 16 384 |

## 2. Analyse des résultats

### 2.1 Tables dominantes

- La table **fait_mesures** représente la majorité du volume (≈ 188 Mo).  
- Les tables `mesures` et `mesure_src` montrent une duplication fonctionnelle probable.
- Présence d’un modèle **type datawarehouse** :
  - tables de faits : fait_mesures  
  - tables dimensions : dim_*







