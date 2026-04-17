# =========================================================
# SCRIPT DE CLASSIFICATION - ECOTRACK
# Objectif : prédire l'état du conteneur (faible / moyen / plein)
# =========================================================

# Import des librairies pour manipulation de données
import pandas as pd              # pour manipuler les tableaux (DataFrame)
import numpy as np               # pour les calculs numériques

# Import pour connexion à la base PostgreSQL (Neon)
from sqlalchemy import create_engine, text

# Import des modèles de machine learning
from sklearn.ensemble import RandomForestClassifier

# Import pour séparer les données
from sklearn.model_selection import train_test_split

# Import pour évaluer le modèle
from sklearn.metrics import accuracy_score, classification_report

# Import pour sauvegarder le modèle
import joblib


# =========================================================
# CONNEXION A LA BASE DE DONNEES
# =========================================================

# URL de connexion à Neon (base cloud PostgreSQL)
CLOUD_DB_URL = "postgresql://neondb_owner:npg_F7R8JiNXuPhk@ep-plain-art-a8q8w3rb-pooler.eastus2.azure.neon.tech/neondb?sslmode=require&channel_binding=require"

# Fonction pour créer une connexion
def get_engine():
    print("Connexion à Neon...")
    try:
        engine = create_engine(CLOUD_DB_URL)  # création du moteur SQL
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))   # test de connexion
        print("Connexion réussie")
        return engine
    except Exception as e:
        print("Erreur :", e)
        return None


# =========================================================
# EXTRACTION DES DONNEES
# =========================================================

engine = get_engine()

# Requête SQL pour récupérer les données
query = """
SELECT 
    id_container,
    timestamp_mesure,
    fill_level_pct
FROM analytics.mesures
ORDER BY id_container, timestamp_mesure;
"""

# Chargement dans pandas
df = pd.read_sql(query, engine)

print(df.head())  # affichage pour vérifier


# =========================================================
# FEATURE ENGINEERING (création de variables)
# =========================================================

# Conversion du timestamp
df["timestamp"] = pd.to_datetime(df["timestamp_mesure"])

# Création de variables temporelles
df["hour"] = df["timestamp"].dt.hour
df["day_of_week"] = df["timestamp"].dt.dayofweek
df["day_of_month"] = df["timestamp"].dt.day

# Variable weekend (1 = oui, 0 = non)
df["is_weekend"] = df["day_of_week"].isin([5,6]).astype(int)

# Variable heure de pointe
df["is_peak_hour"] = df["hour"].isin([8,9,17,18,19]).astype(int)


# =========================================================
# CREATION DE LA VARIABLE CIBLE (CLASSIFICATION)
# =========================================================

# Fonction pour transformer le % en catégorie
def classify_fill_level(x):
    if x < 30:
        return 0   # faible
    elif x < 70:
        return 1   # moyen
    else:
        return 2   # plein

# Application de la fonction
df["fill_category"] = df["fill_level_pct"].apply(classify_fill_level)


# =========================================================
# CREATION DES VARIABLES LAG
# =========================================================

# Tri des données
df = df.sort_values(["id_container", "timestamp"])

# Valeurs passées (important pour ML)
df["fill_rate_1h_ago"] = df.groupby("id_container")["fill_level_pct"].shift(1)
df["fill_rate_24h_ago"] = df.groupby("id_container")["fill_level_pct"].shift(24)
df["fill_rate_7d_ago"] = df.groupby("id_container")["fill_level_pct"].shift(168)

# Suppression des lignes avec valeurs manquantes
df = df.dropna()


# =========================================================
# PREPARATION DES DONNEES
# =========================================================

# Liste des variables explicatives
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

# Variables d'entrée
X = df[features]

# Variable cible
y = df["fill_category"]


# =========================================================
# SPLIT TRAIN / TEST
# =========================================================

X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,     # 20% test
    random_state=42
)


# =========================================================
# ENTRAINEMENT DU MODELE
# =========================================================

model = RandomForestClassifier(
    n_estimators=100,  # nombre d'arbres
    max_depth=10,      # profondeur max
    random_state=42
)

# Entraînement
model.fit(X_train, y_train)


# =========================================================
# EVALUATION
# =========================================================

y_pred = model.predict(X_test)

print("Accuracy :", accuracy_score(y_test, y_pred))
print(classification_report(y_test, y_pred))


# =========================================================
# SAUVEGARDE DU MODELE
# =========================================================

joblib.dump(model, "model_classification.pkl")

print("Modèle de classification sauvegardé")