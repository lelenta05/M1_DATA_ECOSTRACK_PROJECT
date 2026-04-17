# 🌍 ECOTRACK - API de Prédiction du Taux de Remplissage

## 📌 Description du projet

ECOTRACK est une solution basée sur la data permettant de prédire le niveau de remplissage de conteneurs intelligents.

Ce projet combine :
- 🔹 **Machine Learning (Random Forest)**
- 🔹 **API REST avec FastAPI**
- 🔹 **Données stockées sur PostgreSQL (Neon)**

---

## 🎯 Objectifs

L’API permet de :

- 📊 Prédire le **taux de remplissage (%)** → modèle de **régression**
- 🚦 Déterminer l’**état du conteneur** :
  - 🟢 Faible
  - 🟡 Moyen
  - 🔴 Plein  
  → modèle de **classification**

---

## 🧠 Architecture du projet

```bash
project/
│
├── api.py                       # API FastAPI
├── train_regression.py          # Entraînement modèle régression
├── train_classification.py      # Entraînement modèle classification
├── model_fill_rate.pkl          # Modèle régression
├── model_classification.pkl     # Modèle classification
├── README.md