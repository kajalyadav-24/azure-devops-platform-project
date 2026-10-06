from flask import Flask, jsonify
import os
import socket
from datetime import datetime, timezone

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")


@app.route("/", methods=["GET"])
def home():
    return jsonify(
        application="Azure DevOps Incident Service",
        status="running",
        environment=ENVIRONMENT,
        version=APP_VERSION
    ), 200


@app.route("/health", methods=["GET"])
def health():
    return jsonify(
        status="healthy",
        hostname=socket.gethostname(),
        timestamp=datetime.now(timezone.utc).isoformat()
    ), 200


@app.route("/version", methods=["GET"])
def version():
    return jsonify(
        version=APP_VERSION,
        environment=ENVIRONMENT
    ), 200


@app.route("/api/incidents", methods=["GET"])
def incidents():
    sample_incidents = [
        {
            "id": 1001,
            "title": "High CPU utilization",
            "severity": "P2",
            "status": "Resolved"
        },
        {
            "id": 1002,
            "title": "Application health probe failure",
            "severity": "P3",
            "status": "Monitoring"
        }
    ]

    return jsonify(sample_incidents), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False
    )
