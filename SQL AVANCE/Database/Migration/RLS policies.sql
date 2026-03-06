-- Activation RLS
--  Étape 1 : Activer RLS

ALTER TABLE analytics.bins
ENABLE ROW LEVEL SECURITY;
-- Important :
-- Une fois activé, aucune ligne n’est accessible sans policy.

--Policies
-- Policy SELECT – Collecteurs
 --Les collecteurs ne voient que les bins de leur zone.
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

-- Policy SELECT – Admins

--Les admins voient tout :

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

-- Bloquer utilisateurs non authentifiés

--Supabase bloque automatiquement si auth.uid() est NULL.
--Mais on peut être explicite :

CREATE POLICY "Authenticated users only"
ON analytics.bins
FOR SELECT
USING (
    auth.uid() IS NOT NULL
);

 --Politique UPDATE (optionnel avancé)
-- Empêcher un collecteur de modifier des bins hors zone :

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

-- Logique de Sécurité, Ce que fait PostgreSQL en interne
 --Quand un collecteur fait :

SELECT * FROM analytics.bins;

-- PostgreSQL transforme automatiquement en :

SELECT * FROM analytics.bins
WHERE (condition_de_policy);

--Le filtrage est :
- transparent
- automatique
- impossible à contourner côté frontend

 --Validation 
 -- Tests réalisés
 -- Test 1 : Admin

SELECT * FROM analytics.bins;

--Résultat :
-- Toutes les lignes visibles

--Test 2 : Collecteur zone_A

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
