# Import de pandas pour manipuler les données sous forme de tableau
import pandas as pd

# Import de numpy pour effectuer des calculs numériques
import numpy as np

# URL de connexion à la base PostgreSQL Neon
# Remplacer user, password, host et dbname par tes informations
from sqlalchemy import create_engine, text


# 2. INITIALISATION ET CONNEXIONS
#connection avec neon.tech qui va recevoir nos database oltp et olap
CLOUD_DB_URL = "postgresql://neondb_owner:npg_F7R8JiNXuPhk@ep-plain-art-a8q8w3rb-pooler.eastus2.azure.neon.tech/neondb?sslmode=require&channel_binding=require"
# Récupération des variables d'environnement (Docker)
#USER = 'admin'
#PWD = 'admin'

# URLs de connexion
#URL_OLTP = f"postgresql+psycopg2://{USER}:{PWD}@localhost:5432/ecotrack_oltp"
#URL_OLAP = f"postgresql+psycopg2://{USER}:{PWD}@localhost:5433/ecotrack_olap"

def get_engine():
    """Crée et retourne le moteur de connexion"""
    print(" Connexion à Neon.tech...")
    try:
        engine = create_engine(CLOUD_DB_URL)
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        print(" Connexion réussie.")
        return engine
    except Exception as e:
        print(f" Erreur critique de connexion : {e}")
        return None

# Sur le Cloud gratuit, on n'a souvent qu'une seule base ('neondb' ou 'postgres').
# On va donc utiliser des SCHÉMAS pour séparer l'App (OLTP) de l'Analytics (OLAP).
# Schéma 'public' = OLTP (App)
# Schéma 'analytics' = OLAP (Data Warehouse)


# MAIN (Lancement)
if __name__ == "__main__":
    print(" Connexion avec la base terminé")
    # 1. Création du moteur unique
    my_engine = get_engine()
   # load_olap()
   

# Requête SQL pour récupérer les données historiques
query = """
SELECT 
    id_container,
    timestamp_mesure,
    fill_level_pct
FROM analytics.mesures
ORDER BY id_container, timestamp_mesure, fill_level_pct ;
"""

# Exécution de la requête et stockage dans un DataFrame pandas
df = pd.read_sql(query, my_engine)

# Affichage des 5 premières lignes pour vérifier les données
print(df.head())

# Conversion de la colonne timestamp en format date utilisable
df["timestamp"] = pd.to_datetime(df["timestamp_mesure"])

##Création des features temporelles
# Extraction de l'heure (0 à 23)
df["hour"] = df["timestamp"].dt.hour

# Extraction du jour de la semaine (0 = lundi, 6 = dimanche)
df["day_of_week"] = df["timestamp"].dt.dayofweek

# Extraction du jour du mois (1 à 31)
df["day_of_month"] = df["timestamp"].dt.day

# Création d'une variable indiquant si c'est le weekend
df["is_weekend"] = df["day_of_week"].isin([5,6]).astype(int)

# Création d'une variable indiquant si l'heure est une heure de pointe
df["is_peak_hour"] = df["hour"].isin([8,9,17,18,19]).astype(int)

##Création des variables lag
# Tri des données par conteneur et date
df = df.sort_values(["id_container", "timestamp"])

# Taux de remplissage il y a 1 heure
df["fill_rate_1h_ago"] = df.groupby("id_container")["fill_level_pct"].shift(1)

# Taux de remplissage il y a 24 heures
df["fill_rate_24h_ago"] = df.groupby("id_container")["fill_level_pct"].shift(24)

# Taux de remplissage il y a 7 jours
df["fill_rate_7d_ago"] = df.groupby("id_container")["fill_level_pct"].shift(168)

##Nettoyer les données
# Suppression des lignes contenant des valeurs manquantes
df = df.dropna()

##Définir les variables du modèle
# Liste des variables explicatives (features)
features = [
    "hour",
    "day_of_week",
    "day_of_month",
    "is_weekend",
    "is_peak_hour",
    "fill_rate_1h_ago",
    "fill_rate_24h_ago",
    "fill_rate_7d_ago"
]

# Variables d'entrée du modèle
X = df[features]

# Variable cible (ce que l'on veut prédire)
y = df["fill_level_pct"]

##Séparation de  train/test
from sklearn.model_selection import train_test_split

# Séparation des données
# 80% pour l'entraînement
# 20% pour le test
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42
)

##Entraîner le modèle
from sklearn.ensemble import RandomForestRegressor

# Création du modèle Random Forest
model = RandomForestRegressor(
    n_estimators=100,      # nombre d'arbres dans la forêt
    max_depth=10,          # profondeur maximale des arbres
    random_state=42        # pour reproduire les résultats
)

# Entraînement du modèle avec les données d'entraînement
model.fit(X_train, y_train)

##Évaluation du modèle
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

# Prédiction sur les données de test
y_pred = model.predict(X_test)

# Calcul de l'erreur RMSE
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

# Calcul de l'erreur MAE
mae = mean_absolute_error(y_test, y_pred)

# Calcul du coefficient R²
r2 = r2_score(y_test, y_pred)

# Affichage des résultats
print("RMSE :", rmse)
print("MAE :", mae)
print("R2 :", r2)

##Objectif: R² > 0.65

##Sauvegarde du modèle
import joblib

joblib.dump(model, "model_fill_rate.pkl")

#message de confirmation
print("Modele sauvegardé avec succes")