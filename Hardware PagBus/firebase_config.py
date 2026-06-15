import firebase_admin
from firebase_admin import credentials, firestore
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
CAMINHO_CHAVE = BASE_DIR / "firebase-key.json"

try:
    app = firebase_admin.get_app()
except ValueError:
    cred = credentials.Certificate(str(CAMINHO_CHAVE))
    app = firebase_admin.initialize_app(cred)

db = firestore.client(app)