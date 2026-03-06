# Mission 1.3 – Projection de Croissance ECOTRACK

## 1. Volume de lignes sur 1 an

Hypothèses :
- 10 000 poubelles connectées  
- 96 mesures par jour et par poubelle  
- 365 jours

Calcul :

10 000 × 96 × 365 = 350 400 000 lignes / an

➡ La table fait_mesures atteindra environ **350 millions de lignes par an**.

## 2. Estimation de la taille de la table

Une ligne measurements ≈ 60 à 100 bytes.

### Taille minimale
350 400 000 × 60 bytes  
= 21 024 000 000 bytes  
≈ 19,6 Go

### Taille maximale
350 400 000 × 100 bytes  
= 35 040 000 000 bytes  
≈ 32,6 Go

### Avec index (≈ +40%)

Estimation réaliste :

**28 à 45 Go par an** pour la table fait_mesures.

## 3. À partir de quand partitionner PostgreSQL ?

Bonnes pratiques issues de la documentation :

- Au-delà de 50 à 100 millions de lignes  
- Tables time-series avec forte croissance  
- Requêtes majoritairement filtrées par date  
- Maintenance (VACUUM/INDEX) trop longue

Notre cas :

- 350M lignes/an  
- Accès par created_at  
- Dashboard temps réel

"Le partitionnement est OBLIGATOIRE."

### Stratégie proposée

- Partitionnement par mois sur created_at  
- Index locaux par partition  
- Rétention 12 mois en base chaude  
- Archivage au-delà

Exemple :

CREATE TABLE fait_mesures (
  id BIGSERIAL,
  container_id BIGINT,
  niveau INT,
  created_at TIMESTAMPTZ
) PARTITION BY RANGE (created_at);

## 4. Compatibilité avec Supabase Free Tier

Limite Free Tier : 500 MB

Besoin estimé :  
≈ 30–40 Go / an

"Le free tier est totalement insuffisant."

### Plan nécessaire

- Supabase Pro / Team  
- Stockage additionnel  
- Politique d’archivage

Estimation :

- Base active : ~40 Go  
- Backups : ×2  
- Traffic temps réel

➡ Plan Team + stockage objet recommandé.

## 5. Plan de capacité

| Période | Lignes | Taille estimée |
|-------|--------|----------------|
| 6 mois | 175M | 15–20 Go |
| 1 an | 350M | 30–40 Go |
| 2 ans | 700M | 60–80 Go |


## 6. Recommandations finales

1. Mettre en place immédiatement :
- partitionnement mensuel  
- index (container_id, created_at)  
- index BRIN sur created_at

2. Gouvernance :
- rétention 12 mois  
- archivage froid  
- compression

3. Infrastructure :
- quitter free tier  
- monitoring pg_stat_statements  
- stratégie backup
