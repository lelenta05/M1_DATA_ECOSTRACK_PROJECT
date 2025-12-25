-- Database: ecotrack_dw

-- DROP DATABASE IF EXISTS ecotrack_dw;
'''
CREATE DATABASE ecotrack_dw
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'French_France.1252'
    LC_CTYPE = 'French_France.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
'''
--Activation de l'extension postgis
CREATE EXTENSION  IF NOT EXISTS postgis ;
SELECT POSTGIS_VERSION() ;

--CREATION DES TABLES DE DIMENSION 
--DIMENSION TEMPS
CREATE TABLE IF NOT EXISTS DIM_TEMPS (
	id_temps INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
	date_complete DATE NOT NULL,
	annee INTEGER GENERATED ALWAYS AS (EXTRACT (YEAR FROM date_complete)) STORED,
	trimestre INTEGER GENERATED ALWAYS AS (EXTRACT(QUARTER FROM date_complete)) STORED, --QUARTER pour trimestre 
	mois INTEGER GENERATED ALWAYS AS(EXTRACT(MONTH FROM date_complete)) STORED,
	jour_mois INTEGER GENERATED ALWAYS AS (EXTRACT (DAY FROM date_complete))STORED,
	jour_semaine VARCHAR(20) NOT NULL,
	semaine_annee INTEGER NULL,
	trimestre_annee INTEGER NULL,
	est_weekend BOOLEAN DEFAULT FALSE,
	est_ferie BOOLEAN DEFAULT FALSE	
);
--DIMENSION TYPE_DECHET 
CREATE TYPE categorie_type AS ENUM('Papier_Carton','Plastique','Verre','Dechets_Organiques');
CREATE TABLE IF NOT EXISTS DIM_TYPE_DECHETS (
	id_type_dechet INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	type_code VARCHAR(10)UNIQUE NOT NULL,
	nom_type VARCHAR(30) NOT NULL,
	categorie categorie_type NOT NULL
);

--DIMENESION ZONE 
CREATE TABLE IF NOT EXISTS DIM_ZONES(
	id_zone INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	code_zone VARCHAR(10) UNIQUE NOT NULL,
	nom_zone VARCHAR(30) NOT NULL,
	type_zone VARCHAR(30) NOT NULL,
	ville VARCHAR(30) NOT NULL ,
	polygon GEOMETRY(Polygon,4326) NOT NULL,
	arrondissement VARCHAR(30) NOT NULL,
	code_postal INTEGER NOT NULL,
	population INTEGER NOT NULL ,
	nombre_menages INTEGER NOT NULL ,
	taux_recyclage_zone DECIMAL(5,2) NULL,
	nombre_conteneurs_zone INTEGER NOT NULL,
	densite_population DECIMAL(5,2) NULL
);

--DIMENSION AGENT 
CREATE TABLE IF NOT EXISTS DIM_AGENTS(
	id_agent INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	code_agent VARCHAR(10) UNIQUE NOT NULL,
	nom VARCHAR(30) NOT NULL,
	prenom VARCHAR(30) NOT NULL,
	equipe VARCHAR(20) NOT NULL,
	status VARCHAR(20)NOT NULL,
	type_permis CHAR(1) NOT NULL,
	date_embauche DATE NOT NULL,
	vehicule_immatriculation VARCHAR(30) NULL,
	vehicule_type VARCHAR(20)NOT NULL,
	vehicule_date_mise_service DATE NOT NULL,
	vehicule_capacite INTEGER NOT NULL ,
	vehicule_consommation_moyene DECIMAL(5,2) NOT NULL ,
	vehicule_emission_co2_km DECIMAL(5,2) NOT NULL ,
	zone_affecte VARCHAR(20) NOT NULL 
);
-- DIMENSION TOURNEE
CREATE TABLE IF NOT EXISTS DIM_TOURNEES(
	id_tournee INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	code_tournee VARCHAR(10) UNIQUE NOT NULL,
	type_tournee VARCHAR(20) NOT NULL ,
	date_planification DATE NOT NULL ,
	heure_depart TIME NOT NULL ,
	heure_retour TIME NOT NULL ,
	equipe_assigne VARCHAR(20) NOT NULL,
	trajet GEOMETRY(LineString,4326) NOT NULL ,
	distance_estime_km DECIMAL(5,2) NOT NULL ,
	duree_estime_minutes INT NOT NULL ,
	cout_fixe_tournee DECIMAL(5,2) NOT NULL ,
	cout_variable_km DECIMAL(5,2) NOT NULL ,
	carburant_estime_litres DECIMAL(5,2) NOT NULL,
	status VARCHAR(20) NOT NULL,
	priorite VARCHAR(20) NOT NULL
);
--DIMENSION CONTENEUR 
CREATE TABLE IF NOT EXISTS DIM_CONTENEURS (
	id_conteneur INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	code_conteneur VARCHAR(10) UNIQUE NOT NULL,
	status VARCHAR(20)NOT NULL,
	taux_utilisation_moyen DECIMAL(5,2) NOT NULL,
	capacite_litre DECIMAL(5,2) NOT NULL,
	date_installation DATE NOT NULL ,
	type_conteneur VARCHAR(20) NOT NULL ,
	location GEOMETRY(Point,4326) NOT NULL,
	modele_capteur VARCHAR(20) NOT NULL,
	code_capteur VARCHAR(10) UNIQUE NOT NULL ,
	version_capteur VARCHAR(10) NOT NULL ,
	date_installation_capteur DATE NOT NULL ,
	date_maintenance DATE NOT NULL ,
	---SCD Type 2 : historique 
	date_debut DATE NULL ,
	date_fin DATE NULL,
	version INTEGER NULL DEFAULT 1,
	is_current BOOLEAN NULL DEFAULT TRUE 
);

--FAIT
CREATE TABLE IF NOT EXISTS FAIT_MESURES(
	id_fm bigserial,
	id_temps INTEGER NOT NULL ,
	id_conteneur INTEGER NOT NULL ,
	id_zone INTEGER NOT NULL ,
	id_type_dechet INTEGER NOT NULL ,
	id_agent INTEGER NOT NULL ,
	id_tournee INTEGER NOT NULL ,
	taux_remplissage DECIMAL(5,2) NOT NULL ,
	volume_litres DECIMAL(5,2) NOT NULL ,
	temperatures DECIMAL(5,2) NOT NULL ,
	poids_estime INTEGER NOT NULL ,
	timestamp_mesure TIMESTAMP NOT NULL,
	niveau_batterie INTEGER NOT NULL ,
	is_overflow BOOLEAN NOT NULL,
	vibrations DECIMAL(5,2) NULL,
	nb_signalements_actifs INTEGER DEFAULT 0,
	source_mesure VARCHAR(20) NOT NULL ,
	qualite_mesure VARCHAR(20) NULL ,
	PRIMARY KEY (id_fm,timestamp_mesure),--obligatoire de mettre timestamp_mesure dans la cle primaire pour le partitionnement
	CONSTRAINT fk_temps FOREIGN KEY (id_temps) REFERENCES DIM_TEMPS(id_temps),
	CONSTRAINT fk_conteneur FOREIGN KEY(id_conteneur) REFERENCES DIM_CONTENEURS (id_conteneur),
	CONSTRAINT fk_zone FOREIGN KEY(id_zone) REFERENCES DIM_ZONES(id_zone),
	CONSTRAINT fk_type_dechet FOREIGN KEY(id_type_dechet) REFERENCES DIM_TYPE_DECHETS(id_type_dechet),
	CONSTRAINT fk_agent FOREIGN KEY(id_agent) REFERENCES DIM_AGENTS(id_agent),
	CONSTRAINT fk_tournee FOREIGN KEY(id_tournee) REFERENCES DIM_TOURNEES(id_tournee)
	)PARTITION BY RANGE(timestamp_mesure);

--CREATION DES DIFFERENTES TABLES DE PARTITION : 1ans donc 12 mois
CREATE TABLE fill_history_202401 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-01-01 00:00:00') TO ('2024-01-31 00:00:00');
CREATE TABLE fill_history_202402 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-02-01 00:00:00') TO ('2024-02-28 00:00:00');
CREATE TABLE fill_history_202403 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-03-01 00:00:00') TO ('2024-03-30 00:00:00');
CREATE TABLE fill_history_202404 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-04-01 00:00:00') TO ('2024-04-31 00:00:00');
CREATE TABLE fill_history_202405 PARTITION OF FAIT_MESURES FOR VALUES FROM('2024-05-01  00:00:00') TO ('2024-05-30 00:00:00');
CREATE TABLE fill_history_202406 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-06-01 00:00:00') TO ('2024-06-31 00:00:00');
CREATE TABLE fill_history_202407 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-07-01 00:00:00') TO ('2024-07-30 00:00:00');
CREATE TABLE fill_history_202408 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-08-01 00:00:00') TO ('2024-08-31 00:00:00');
CREATE TABLE fill_history_202409 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-09-01 00:00:00') TO ('2024-09-30 00:00:00');
CREATE TABLE fill_history_202410 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-10-01 00:00:00') TO ('2024-10-31 00:00:00');
CREATE TABLE fill_history_202411 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-11-01 00:00:00') TO ('2024-11-30 00:00:00');
CREATE TABLE fill_history_202412 PARTITION OF FAIT_MESURES FOR VALUES FROM ('2024-12-01 00:00:00') TO ('2024-12-31 00:00:00');

--CREATION DES INDEXES 
--INDEX SPATIAL GIST
CREATE INDEX idx_zone_polygon ON DIM_ZONES USING GIST(polygon);
CREATE INDEX idx_containeur_location ON DIM_CONTENEURS USING GIST(location);
--INDEX SUR LES COLONNES TEMPORELLES 
CREATE INDEX idx_temps_date_complete ON DIM_TEMPS (date_complete);
CREATE INDEX idx_conteneur_date ON DIM_CONTENEURS(date_installation,date_installation_capteur) ;
CREATE INDEX idx_tournee_date_heure ON DIM_TOURNEES (date_planification,heure_depart,heure_retour);
CREATE INDEX idx_agent_date ON DIM_AGENTS (date_embauche);
--INDEX SUR L'ID DE LA DATE POUR TROUVE TRES VITE LES MESURES EN UNE DATE DONNEE et AVEC L'ID DE LA DIM_TEMPS
CREATE INDEX idx_fait_temps ON FAIT_MESURES(id_temps) ;
CREATE INDEX idx_fait_timestamp ON FAIT_MESURES(timestamp_mesure) ;


--CREATE DES TABLES RELATIONNELLES 
--STATISTIQUES_QUOTIDIENNES_AGRÉGÉES
CREATE TABLE IF NOT EXISTS AGGREGATED_DAILY_STATS (
	date_complete DATE PRIMARY KEY,
	id_zone INTEGER NOT NULL ,
	nb_mesures_total DECIMAL(5,2) NOT NULL ,
	taux_moyen DECIMAL(5,2) NOT NULL ,
	temperature_moyenne DECIMAL(5,2) NOT NULL ,
	nb_conteneurs_actifs INTEGER NOT NULL ,
	taux_remplissage DECIMAL(5,2),
	CONSTRAINT fk_zone FOREIGN KEY(id_zone) REFERENCES DIM_ZONES(id_zone)
);

--PREDICTION MACHINE LEARNING 
CREATE TABLE IF NOT EXISTS ML_PREDICTIONS (
	id_ml_prediction INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
	id_conteneur INTEGER NOT NULL ,
	date_prediction DATE NOT NULL ,
	taux_remplissage_prediction DECIMAL(5,20) NOT NULL ,
	confiance_prediction DECIMAL(5,2) NOT NULL ,
	modele_utilise VARCHAR(50) NOT NULL ,
	date_calcul  DATE NOT NULL,
	CONSTRAINT fk_conteneur FOREIGN KEY(id_conteneur) REFERENCES DIM_CONTENEURS(id_conteneur)
);

--CREATION DE SES INDEX 
CREATE INDEX idx_date ON ML_PREDICTIONS (date_prediction,date_calcul) ; 
CREATE INDEX idx_pd_conteneur ON ML_PREDICTIONS(id_conteneur) ;




