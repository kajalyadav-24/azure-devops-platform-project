from flask import Flask, jsonify, render_template
import os
import socket
from datetime import datetime, timezone

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")


@app.route("/", methods=["GET"])
def home():
    incidents = [
        {
            "id": 1001,
            "title": "High CPU utilization",
            "severity": "P2",
            "status": "Resolved",
            "service": "payment-api"
        },
        {
            "id": 1002,
            "title": "Application health probe failure",
            "severity": "P3",
            "status": "Monitoring",
            "service": "incident-api"
        },
        {
            "id": 1003,
            "title": "AKS pod restart detected",
            "severity": "P3",
            "status": "Investigating",
            "service": "frontend-service"
        }
    ]

    return render_template(
        "index.html",
        app_name="Azure Cloud Operations Platform",
        environment=ENVIRONMENT,
        version=APP_VERSION,
        hostname=socket.gethostname(),
        incidents=incidents,
        current_time=datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    )


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
    incident_data = [
        {
            "id": 1001,
            "title": "High CPU utilization",
            "severity": "P2",
            "status": "Resolved",
            "service": "payment-api"
        },
        {
            "id": 1002,
            "title": "Application health probe failure",
            "severity": "P3",
            "status": "Monitoring",
            "service": "incident-api"
        },
        {
            "id": 1003,
            "title": "AKS pod restart detected",
            "severity": "P3",
            "status": "Investigating",
            "service": "frontend-service"
        }
    ]

    return jsonify(incident_data), 200


if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False
    )