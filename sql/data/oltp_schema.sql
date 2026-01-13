--DATABASE OLTP 
--CREATE DATABASE ecotrack_oltp ;

--ACTIVATION DE L'EXTENSION POSTGIS 
CREATE EXTENSION IF NOT EXISTS postgis ;
SELECT POSTGIS_VERSION();

-- D'abord activer l'extension :
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

--CREATION DES TABLES DE L'OLTP 

CREATE TABLE IF NOT EXISTS USERS(
    id_user INTEGER  PRIMARY KEY ,
    email VARCHAR(255) NOT NULL UNIQUE ,
    password VARCHAR(225) NOT NULL,
    firstname VARCHAR(20) NOT NULL ,
    lastname VARCHAR(20) NOT NULL ,
    points INTEGER NULL  DEFAULT 0,
    is_active BOOLEAN  DEFAULT TRUE NOT NULL ,
    created_at TIMESTAMP NOT NULL 
);

CREATE TABLE IF NOT EXISTS ROLES(
    id_role INTEGER  PRIMARY KEY ,
    name VARCHAR (20) NOT NULL ,
    description TEXT NULL ,
    CONSTRAINT chk_role CHECK (name IN ('citoyen','agent','gestionnaire','admin'))
);
CREATE TABLE IF NOT EXISTS USERS_ROLES(
    id_user_role INTEGER  PRIMARY KEY ,
    id_user INTEGER NOT NULL REFERENCES USERS(id_user) ON DELETE CASCADE,
    id_role INTEGER NOT NULL REFERENCES ROLES(id_role) ON DELETE CASCADE,
    assigned_at TIMESTAMP NOT NULL  --assigne a 
);
CREATE TABLE IF NOT EXISTS BADGES(
    id_badge INTEGER  PRIMARY KEY ,
    code_badge VARCHAR(10) NOT NULL,
    name VARCHAR(30) NOT NULL ,
    description TEXT NULL 
);

CREATE TABLE IF NOT EXISTS USERS_BADGES (
    id_user_badge INTEGER  PRIMARY KEY ,
    id_user INTEGER NOT NULL REFERENCES USERS(id_user) ON DELETE CASCADE ,
    id_badge INTEGER NOT NULL REFERENCES BADGES(id_badge) ON DELETE CASCADE,
    earned_at TIMESTAMP NOT NULL --gagne a 
);

CREATE TABLE IF NOT EXISTS ZONES(
    id_zone INTEGER  PRIMARY KEY ,
    code_zone VARCHAR(10) NOT NULL ,
    name VARCHAR(20) NOT NULL ,
    population INTEGER NOT NULL ,
    area_km2 DECIMAL(10,2) NOT NULL ,--SUPERFICIE
    polygon  GEOMETRY(Polygon, 4326) NOT NULL 
);
CREATE TABLE IF NOT EXISTS CONTAINER_TYPES (
    id_container_type INTEGER  PRIMARY KEY ,
    code_container_type VARCHAR(10) NOT NULL ,
    name VARCHAR(20) NOT NULL,
    description TEXT NULL
);

CREATE TABLE IF NOT EXISTS CONTAINERS(
    id_container INTEGER PRIMARY KEY ,
    uuid_container UUID DEFAULT uuid_generate_v4() NOT NULL UNIQUE ,
    capacity_l DECIMAL(5,2) NOT NULL ,
    status VARCHAR(20) DEFAULT 'actif' NOT NULL,
    install_date DATE NOT NULL ,
    location  GEOMETRY(Point, 4326) NOT NULL ,
    container_type INTEGER NOT NULL REFERENCES CONTAINER_TYPES(id_container_type),
    id_zone INTEGER NOT NULL REFERENCES ZONES(id_zone)
);

CREATE TABLE IF NOT EXISTS CAPTEURS(
    id_capteur INTEGER  PRIMARY KEY ,
    uuid_capteur UUID DEFAULT uuid_generate_v4() NOT NULL UNIQUE ,
    model VARCHAR(30) NOT NULL ,
    firware_version VARCHAR(20) NOT NULL ,--version_du_micrologiciel
    last_seen TIMESTAMP NULL, --derniere vue 
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container)
);

CREATE TABLE IF NOT EXISTS MAINTENANCES(
    id_maintenance INTEGER  PRIMARY KEY ,
    maintenance_type VARCHAR(20) NOT NULL ,
    status VARCHAR(20) DEFAULT 'ATTENTE',
    sheduled_at DATE NOT NULL , --PROGRAMME A 
    performed_at TIMESTAMP , --PERFORMER A 
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container),
    id_capteur INTEGER NOT NULL REFERENCES CAPTEURS(id_capteur)
);
CREATE TABLE IF NOT EXISTS VEHICULES(
    id_vehicule INTEGER  PRIMARY KEY,
    registration_number VARCHAR(20) NOT NULL ,--numero d'immatriculation 
    model VARCHAR(20) NOT NULL ,
    capacite DECIMAL(5,2) NOT NULL ,
    consommation_moyenne DECIMAL(5,2) NOT NULL ,
    emission_co2_km DECIMAL(5,2) NOT NULL 
);

CREATE TABLE IF NOT EXISTS ROUTES(--TOURNEE
    id_route INTEGER PRIMARY KEY ,
    code VARCHAR(10) NOT NULL ,
    date DATE NOT NULL ,
    status VARCHAR(20) NOT NULL,
    distance_m DECIMAL(5,2) NOT NULL ,
    duration_min INTEGER NOT NULL , 
    id_vehicule INTEGER NOT NULL REFERENCES VEHICULES(id_vehicule),
    id_agent INTEGER NOT NULL REFERENCES USERS(id_user)--a l'aide du trigger on va verifie si l'user_id a le role est agent 
);
--UTILISATION UN TRIGGER POUR QUE LE ROLE SOIT UNIQUEMENT AGENT BIGINT
--debut 
-- CREATION DE LA FONCTION DE VERIFICATION DU ROLE 
CREATE OR REPLACE FUNCTION check_agent_role()
--specifie que la fonction est pour un trigger avec as $$ pour delimite le debut du code
RETURNS TRIGGER AS $$ 
DECLARE 
    is_agent BOOLEAN;
BEGIN
    --Verification du role du l'user == agent BIGINT
    SELECT EXISTS (
        SELECT 1 FROM USERS_ROLES ur
        JOIN ROLES r ON ur.id_role = r.id_role
        WHERE ur.id_user = NEW.id_agent AND r.name = 'agent' -- Valeur de la colonne id_agent qu'on essaie
    ) INTO is_agent ; --stocke le resultat

    -- si le role n'est pas agent , lever une exception 
    --RAISE EXCEPTION : Annule la transaction et retourne l'erreur et % va faire reference au New.id_agent c'est a dire l'utilisateur qu'on voulait inserer 
    IF NOT is_agent THEN
        RAISE EXCEPTION 
            'Utilisateur avec l'' ID % n''a pas le role agent. Impossible de l''assigner a la table route (tournée). ',
            NEW.id_agent ;
    END IF ;

    --SINON , AUTORISE L'OPERATION 
    RETURN NEW ; --representer la nouvelle ligne inserer
END 
$$ LANGUAGE plpgsql;

--CREATION DU TRIGGER 
CREATE TRIGGER agent_role 
BEFORE INSERT OR UPDATE OF id_agent ON ROUTES
FOR EACH ROW 
EXECUTE FUNCTION check_agent_role();
--fin
CREATE TABLE IF NOT EXISTS ROUTE_STEPS(
    id_route_step INTEGER  PRIMARY KEY ,
    sequence INTEGER NOT NULL ,--INDIQUE L'ORDRE DE PASSGGE (1,2,..)
    eta TIMESTAMP NOT NULL, -- estimated time of arrival
    collected BOOLEAN DEFAULT FALSE , --collecte ou pas
    id_route INTEGER NOT NULL REFERENCES ROUTES(id_route),
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container) 
);
CREATE TABLE IF NOT EXISTS COLLECTIONS(
    id_collection INTEGER  PRIMARY KEY ,
    collection_at TIMESTAMP,
    qauntite_kg DECIMAL(10,2) NOT NULL ,
    sequence INTEGER NOT NULL ,
    id_route INTEGER NOT NULL REFERENCES ROUTES(id_route),
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container)
);
CREATE TABLE IF NOT EXISTS SIGNALEMENTS(
    id_signalement INTEGER  PRIMARY KEY ,
    signalement_type VARCHAR(30) NOT NULL,
    description TEXT NULL ,
    status VARCHAR(20) NOT NULL DEFAULT 'NON-TRAITE',
    priority VARCHAR(20) NOT NULL DEFAULT 'FAIBLE',
    created_at TIMESTAMP NOT NULL ,
    id_user INTEGER NOT NULL REFERENCES USERS(id_user),
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container)
);

CREATE TABLE IF NOT EXISTS SIGNALEMENT_TREATMENTS(
    id_treatment INTEGER  PRIMARY KEY ,
    treated_at TIMESTAMP NOT NULL ,
    comment TEXT NULL ,
    id_signalement INTEGER NOT NULL REFERENCES SIGNALEMENTS(id_signalement),
    id_agent INTEGER NOT NULL REFERENCES USERS(id_user)
);
--ON A UTILISE LA MEME FONCTION QUE POUR ROUTE 
CREATE TRIGGER treatment_agent_role 
BEFORE INSERT OR UPDATE OF id_agent ON SIGNALEMENT_TREATMENTS 
FOR EACH ROW 
EXECUTE FUNCTION check_agent_role() ;

CREATE TABLE IF NOT EXISTS MESURES(
    id_mesure INTEGER  PRIMARY KEY ,
    distance_brute_mm DECIMAL(5,2) NOT NULL ,
    fill_level_pct DECIMAL(5,2) NOT NULL ,
    battery_pct DECIMAL(5,2) NOT NULL ,
    temperature DECIMAL (5,2) NOT NULL,
    volume_litre DECIMAL(5,2) NOT NULL ,
    timestamp_mesure TIMESTAMP NOT NULL ,
    id_container INTEGER NOT NULL REFERENCES CONTAINERS(id_container),
    id_capteur INTEGER NOT NULL REFERENCES CAPTEURS(id_capteur)
);


--creation des index sur les cle etangeres car pour les cles primaires s'est automatique 
--index pour les colonnes geometriques
CREATE INDEX idx_zone_polygon ON ZONES USING GIST(polygon) ;
CREATE INDEX idx_container_location ON CONTAINERS USING GIST (location);

--index sur tous les cles etrangeres 
--mesures
CREATE INDEX idx_container_mesure ON MESURES(id_container) ;
CREATE INDEX idx_capteur_mesure ON MESURES(id_capteur) ;
--signalements
CREATE INDEX idx_id_user_signalement ON SIGNALEMENTS(id_user);
CREATE INDEX idx_id_container_signalement ON SIGNALEMENTS(id_container);
--signalement_treatment
CREATE INDEX idx_id_agent_signalement_treatment ON SIGNALEMENT_TREATMENTS(id_signalement) ;
CREATE INDEX idx_id_signalement_signalement_treatment ON SIGNALEMENT_TREATMENTS(id_signalement) ;
--collections
CREATE INDEX idx_id_route_collection ON COLLECTIONS(id_route);
CREATE INDEX idx_id_container_collection ON COLLECTIONS(id_container) ;
--routes
CREATE INDEX idx_id_vehicule_route ON ROUTES(id_vehicule) ;
CREATE INDEX idx_id_agent_route ON ROUTES (id_agent) ;
--route_step
CREATE INDEX idx_id_route_step ON ROUTE_STEPS(id_route) ;
CREATE INDEX idx_id_container_step ON ROUTE_STEPS(id_container) ;
--container 
CREATE INDEX idx_id_zone_container ON CONTAINERS(id_zone);
--capteur
CREATE INDEX idx_id_container_capteur ON CAPTEURS(id_container);
--user_badge
CREATE INDEX idx_id_user_badge ON USERS_BADGES(id_user);
CREATE INDEX idx_id_badge ON USERS_BADGES(id_badge);

--user_role
CREATE INDEX idx_id_user_ur ON USERS_ROLES(id_user);
CREATE INDEX idx_id_role ON USERS_ROLES(id_role);

--MAINTENANCE
CREATE INDEX idx_id_container_maintenance ON MAINTENANCES(id_container);
CREATE INDEX idx_id_capteur ON MAINTENANCES(id_capteur);



