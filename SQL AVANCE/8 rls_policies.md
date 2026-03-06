## Row Level Security (RLS) avec Supabase
 # Comprendre Row Level Security
 1. Qu’est-ce que le RLS dans PostgreSQL ?

Le Row Level Security (RLS) est une fonctionnalité native de PostgreSQL permettant de :
- Filtrer automatiquement les lignes visibles ou modifiables selon l’utilisateur connecté.
Contrairement aux permissions classiques (GRANT SELECT ON table),
le RLS agit ligne par ligne.

- Ce n’est pas un simple contrôle au niveau table.
- C’est un filtre dynamique appliqué à chaque requête :
SELECT,INSERT,UPDATE,DELETE

Même si un utilisateur a un GRANT SELECT,
# sans policy RLS valide, il ne voit aucune ligne.
il donctionne via : "CREATE POLICY"

2. Comment Supabase utilise RLS ?

Supabase s’appuie entièrement sur RLS.
Supabase :
- Authentifie les utilisateurs via JWT
- Injecte l’ID utilisateur dans la session PostgreSQL
- Rend disponible la fonction :
auth.uid()
"auth.uid()" retourne l’UUID de l’utilisateur connecté.

# Chaque requête envoyée depuis le frontend passe par RLS.
# Exemple :
--sql:
auth.uid()

# Retourne :
550e8400-e29b-41d4-a716-446655440000

## Cas d’usage : Sécuriser la table bins

# Objectif métier :
- Un collecteur ne voit que les poubelles de sa zone
- Un admin voit tout
- Un utilisateur non authentifié ne voit rien

## Hypothèses de schéma
# Table users :
--sql:

user_id UUID PRIMARY KEY,
role TEXT,              -- 'collector' ou 'admin'
assigned_zone TEXT

--sql
# Colonnes importantes :

- id (UUID, lié à auth.users)
- role (admin / collector)
- zone

# Table bins :
--sql:

bin_id SERIAL PRIMARY KEY,
zone TEXT,
fill_level INTEGER

 --sql

 ## Activation RLS
1. Étape 1 : Activer RLS

ALTER TABLE analytics.bins
ENABLE ROW LEVEL SECURITY;
# Important :
Une fois activé, aucune ligne n’est accessible sans policy.

# Policies
1. Policy SELECT – Collecteurs
 - Les collecteurs ne voient que les bins de leur zone.
 --sql :
 CREATE POLICY "Collectors can see their zone bins"
ON analytics.bins
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM analytics.users u
        WHERE u.id = auth.uid()
        AND u.role = 'collector'
        AND u.zone = bins.assigned_zone
    )
);
2. Policy SELECT – Admins

Les admins voient tout :

CREATE POLICY "Admins can see all bins"
ON analytics.bins
FOR SELECT
USING (
    EXISTS (
        SELECT 1
        FROM analytics.users u
        WHERE u.id = auth.uid()
        AND u.role = 'admin'
    )
);

3. Bloquer utilisateurs non authentifiés

Supabase bloque automatiquement si auth.uid() est NULL.

Mais on peut être explicite :

CREATE POLICY "Authenticated users only"
ON analytics.bins
FOR SELECT
USING (
    auth.uid() IS NOT NULL
);

 # Politique UPDATE (optionnel avancé)

- Empêcher un collecteur de modifier des bins hors zone :

CREATE POLICY "Collectors update only their zone"
ON analytics.bins
FOR UPDATE
USING (
    EXISTS (
        SELECT 1
        FROM analytics.users u
        WHERE u.id = auth.uid()
        AND u.role = 'collector'
        AND u.zone = bins.assigned_zone
    )
);
# Logique de Sécurité
Ce que fait PostgreSQL en interne
- Quand un collecteur fait :

SELECT * FROM analytics.bins;

- PostgreSQL transforme automatiquement en :

SELECT * FROM analytics.bins
WHERE (condition_de_policy);

Le filtrage est :
- transparent
- automatique
- impossible à contourner côté frontend

## Validation – Tests réalisés
1. Test 1 : Admin

Utilisateur :

id|	role|	zone|
A1|	admin	zone_A|

# Requête :

SELECT * FROM analytics.bins;

Résultat :
- Toutes les lignes visibles

Test 2 : Collecteur zone_A

Utilisateur :

id|	role|	zone|
C1|	collector|	zone_A|

Résultat :

- Seulement bins où assigned_zone = zone_A
- Aucune donnée zone_B

Test 3 : Non authentifié

auth.uid() = NULL

Résultat :

- pas de ligne retournée

# Architecture Sécurisée Supabase

- Avantages du RLS :
- Sécurité côté base
- Impossible à contourner via API
- Multitenant sécurisé
- Compatible mobile / frontend direct

C’est une sécurité :

Database-first security

## Résumé des Policies
Policy	Type	Objectif
Collectors SELECT	SELECT	Filtrer par zone
Admin SELECT	SELECT	Accès global
Auth only	SELECT	Bloquer anonymes
Collector UPDATE	UPDATE	Modifier seulement sa zone


