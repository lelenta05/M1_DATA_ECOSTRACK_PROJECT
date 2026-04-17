# =========================================================
# API ECOTRACK - Régression + Classification
# =========================================================

# Import du framework FastAPI
from fastapi import FastAPI

# Import de Pydantic pour valider les données entrantes
from pydantic import BaseModel

# Import de joblib pour charger les modèles
import joblib

# Import de numpy pour structurer les données
import numpy as np

# =========================================================
# INITIALISATION
# =========================================================

# Création de l'application FastAPI
app = FastAPI(title="API ECOTRACK", version="2.0")

# Chargement des modèles (au démarrage de l'API)
try:
    model_reg = joblib.load("model_fill_rate.pkl")          # modèle de régression
    model_clf = joblib.load("model_classification.pkl")     # modèle de classification
    print("✅ Modèles chargés avec succès")
except Exception as e:
    print("❌ Erreur chargement modèles :", e)
    model_reg = None
    model_clf = None

# =========================================================
# SCHEMA DES DONNEES (VALIDATION)
# =========================================================

class InputData(BaseModel):
    hour: int
    day_of_week: int
    day_of_month: int
    is_weekend: int
    is_peak_hour: int
    fill_rate_1h_ago: float
    fill_rate_24h_ago: float
    fill_rate_7d_ago: float

# =========================================================
# ROUTES API
# =========================================================

# Route de test
@app.get("/")
def home():
    return {"message": "✅ API ECOTRACK active"}

# =========================================================
# PREDICTION REGRESSION
# =========================================================

@app.post("/predict")
def predict(data: InputData):

    # Vérification modèle
    if model_reg is None:
        return {"error": "Modèle de régression non chargé"}

    try:
        # Transformation des données en tableau numpy
        features = np.array([[

            data.hour,
            data.day_of_week,
            data.day_of_month,
            data.is_weekend,
            data.is_peak_hour,
            data.fill_rate_1h_ago,
            data.fill_rate_24h_ago,
            data.fill_rate_7d_ago

        ]])

        # Prédiction
        prediction = model_reg.predict(features)

        return {
            "prediction_fill_rate": float(prediction[0])
        }

    except Exception as e:
        return {
            "error": str(e)
        }

# =========================================================
# PREDICTION CLASSIFICATION
# =========================================================

@app.post("/predict_classification")
def predict_classification(data: InputData):

    # Vérification modèle
    if model_clf is None:
        return {"error": "Modèle de classification non chargé"}

    try:
        # Transformation des données
        features = np.array([[

            data.hour,
            data.day_of_week,
            data.day_of_month,
            data.is_weekend,
            data.is_peak_hour,
            data.fill_rate_1h_ago,
            data.fill_rate_24h_ago,
            data.fill_rate_7d_ago

        ]])

        # Prédiction
        prediction = model_clf.predict(features)[0]

        # Mapping des classes
        labels = {
            0: "faible",
            1: "moyen",
            2: "plein"
        }

        return {
            "classe": labels[prediction]
        }

    except Exception as e:
        return {
            "error": str(e)
        }

# =========================================================
# LANCEMENT
# =========================================================

# Lancer avec : python api.py
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)