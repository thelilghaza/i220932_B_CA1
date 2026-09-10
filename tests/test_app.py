import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import app

def test_home():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    data = response.get_json()
    assert data["service"] == "mlops-demo"
    assert data["status"] == "running"

def test_health():
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    data = response.get_json()
    assert data["status"] == "healthy"
    assert "model_version" in data
    assert "application_version" in data
    assert "git_commit" in data

def test_prediction():
    client = app.test_client()
    response = client.post("/predict", json={"value": 5})
    assert response.status_code == 200
    data = response.get_json()
    assert data["prediction"] == 10
    assert data["input"] == 5

def test_prediction_invalid():
    client = app.test_client()
    response = client.post("/predict", json={})
    assert response.status_code == 400
