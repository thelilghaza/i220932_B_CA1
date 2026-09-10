import os
import subprocess
from flask import Flask, jsonify, request

app = Flask(__name__)

# Determine Application Version
def get_app_version():
    if os.environ.get("APP_VERSION"):
        return os.environ.get("APP_VERSION").strip()
    version_file = os.path.join(os.path.dirname(__file__), "VERSION")
    if os.path.isfile(version_file):
        try:
            with open(version_file, "r") as f:
                return f.read().strip()
        except Exception:
            pass
    return "1.0.0"

# Determine Git Commit Hash for Traceability
def get_git_commit():
    if os.environ.get("GIT_COMMIT"):
        return os.environ.get("GIT_COMMIT").strip()
    try:
        commit = subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"],
            stderr=subprocess.DEVNULL
        ).decode("utf-8").strip()
        if commit:
            return commit
    except Exception:
        pass
    return "unknown"

APP_VERSION = get_app_version()
MODEL_VERSION = os.environ.get("MODEL_VERSION", "1.1")
GIT_COMMIT = get_git_commit()

@app.route("/")
def home():
    return jsonify({
        "service": "mlops-demo",
        "status": "running"
    })

@app.route("/health")
def health():
    return jsonify({
        "application_version": get_app_version(),
        "model_version": os.environ.get("MODEL_VERSION", MODEL_VERSION),
        "git_commit": get_git_commit(),
        "status": "healthy"
    })

@app.route("/predict", methods=["POST"])
def predict():
    data = request.get_json(silent=True)
    if not data or "value" not in data:
        return jsonify({"error": "Missing 'value' field in JSON payload"}), 400
    try:
        value = float(data["value"])
    except (ValueError, TypeError):
        return jsonify({"error": "'value' must be a valid number"}), 400

    # Dummy ML prediction for demonstration
    prediction = value * 2
    return jsonify({
        "input": value,
        "prediction": prediction,
        "model_version": os.environ.get("MODEL_VERSION", MODEL_VERSION)
    })

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)
