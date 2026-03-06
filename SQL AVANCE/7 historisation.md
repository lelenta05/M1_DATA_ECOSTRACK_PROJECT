# conception table d'historique utilisateurs
--CREATE TABLE analytics.users_history (
--    history_id SERIAL PRIMARY KEY,
--    user_id INTEGER NOT NULL,          --identifiant métier stable
--    email TEXT,
--    name TEXT,
--    role TEXT,
--    zone TEXT,
--    valid_from TIMESTAMP NOT NULL,
--    valid_to TIMESTAMP,
--    is_current BOOLEAN NOT NULL DEFAULT true
--);

## Questions metiers
 # 1-Quel était le rôle du user 123 le 15 mars 2025 ? On interroge la ligne valide à cette date ?
--SELECT role
--FROM analytics.users_history
--WHERE user_id = 123
--AND '2025-03-15' BETWEEN valid_from AND COALESCE(valid_to, NOW());

 # 2-Quand user 456 a-t-il changé de zone ? Chaque nouvelle ligne correspond à un changement ?
--SELECT valid_from, zone
--FROM analytics.users_history
--WHERE user_id = 456
--ORDER BY valid_from;


## Trigger PostgreSQL
1. Qu’est-ce qu’un trigger ?

Un trigger est un mécanisme automatique :

Il exécute une fonction lorsqu’un événement se produit
(INSERT / UPDATE / DELETE)

Dans notre cas :

 # AFTER UPDATE sur la table users

## Fonction Trigger (SCD Type 2)
- Hypothèse : table source
CREATE TABLE analytics.users (
    user_id INTEGER PRIMARY KEY,
    email TEXT,
    name TEXT,
    role TEXT,
    zone TEXT
);
 # Étape 1 : Fonction PL/pgSQL
CREATE OR REPLACE FUNCTION analytics.fn_users_scd2()
RETURNS trigger AS
$$
BEGIN

    1. Fermer l’ancienne version
    UPDATE analytics.users_history
    SET 
        valid_to = NOW(),
        is_current = false
    WHERE user_id = OLD.user_id
      AND is_current = true;

    2. Insérer la nouvelle version
    INSERT INTO analytics.users_history (
        user_id,
        email,
        name,
        role,
        zone,
        valid_from,
        valid_to,
        is_current
    )
    VALUES (
        NEW.user_id,
        NEW.email,
        NEW.name,
        NEW.role,
        NEW.zone,
        NOW(),
        NULL,
        true
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

 # Étape 2 : Création du trigger
CREATE TRIGGER trg_users_scd2
AFTER UPDATE ON analytics.users
FOR EACH ROW
WHEN (
    OLD.email IS DISTINCT FROM NEW.email OR
    OLD.name IS DISTINCT FROM NEW.name OR
    OLD.role IS DISTINCT FROM NEW.role OR
    OLD.zone IS DISTINCT FROM NEW.zone
)
EXECUTE FUNCTION analytics.fn_users_scd2();

# Pourquoi IS DISTINCT FROM ?

Car : Gère correctement les NULL

Plus sûr que <>

 # Initialisation (Important)

Lors de la création d’un utilisateur, il faut aussi insérer une première version :

INSERT INTO analytics.users_history (
    user_id, email, name, role, zone,
    valid_from, valid_to, is_current
)
SELECT 
    user_id, email, name, role, zone,
    NOW(), NULL, true
FROM analytics.users;

 ## Validation / Tests
 # Étape 1 : Vérifier état initial

SELECT * FROM analytics.users_history
WHERE user_id = 1;

 # Résultat :
user_id	role|zone|is_current|
agent|zone_A|true|

 # Étape 2 : Modifier utilisateur
UPDATE analytics.users
SET zone = 'zone_B'
WHERE user_id = 1;

 # Étape 3 : Vérifier historique
SELECT user_id, role, zone, valid_from, valid_to, is_current
FROM analytics.users_history
WHERE user_id = 1
ORDER BY valid_from;

 # Résultat :

user_id	role|	zone|	valid_to|	is_current
1|	agent|	zone_A|	2026-03-05|	false
1|	agent|	zone_B|	NULL|	true

On a bien :

# Ancienne version fermée

# Nouvelle version active

 ## Architecture moderne – Pourquoi c’est puissant ?

 # Avantages :

- Historique complet
- Audit RGPD
- Reconstitution d’état passé
- Compatible BI / Data Warehouse
- Compatible Supabase