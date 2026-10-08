import logging
import os
from datetime import datetime, timezone

from flask import Flask, jsonify, render_template
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


# ---------------------------------------------------------
# Flask application
# ---------------------------------------------------------
app = Flask(__name__)  # NOSONAR


# ---------------------------------------------------------
# Logging
# ---------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s"
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------
# Application configuration
# ---------------------------------------------------------
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")

KEY_VAULT_URI = os.getenv("KEY_VAULT_URI")
KEY_VAULT_SECRET_NAME = "incident-app-demo"


# ---------------------------------------------------------
# Demo incident data
# ---------------------------------------------------------
INCIDENTS = [
    {
        "id": "INC001",
        "title": "High CPU utilization",
        "severity": "High",
        "status": "Investigating",
        "service": "Azure VM"
    },
    {
        "id": "INC002",
        "title": "Application latency detected",
        "severity": "Medium",
        "status": "Monitoring",
        "service": "AKS"
    },
    {
        "id": "INC003",
        "title": "Backup completed successfully",
        "severity": "Low",
        "status": "Resolved",
        "service": "Azure Backup"
    }
]


# ---------------------------------------------------------
# Key Vault helper
# ---------------------------------------------------------
def get_key_vault_secret():
    """
    Read a secret from Azure Key Vault.

    In AKS this uses Azure Workload Identity through
    DefaultAzureCredential.

    No client secret/password is stored in the application.
    """

    if not KEY_VAULT_URI:
        raise RuntimeError(
            "KEY_VAULT_URI environment variable is not configured"
        )

    credential = DefaultAzureCredential()

    secret_client = SecretClient(
        vault_url=KEY_VAULT_URI,
        credential=credential
    )

    secret = secret_client.get_secret(KEY_VAULT_SECRET_NAME)

    return secret.value


# ---------------------------------------------------------
# Home page
# ---------------------------------------------------------
@app.route("/")
def home():
    return render_template(
        "index.html",
        app_version=APP_VERSION,
        environment=ENVIRONMENT,
        incidents=INCIDENTS
    )


# ---------------------------------------------------------
# Health endpoint
# Kubernetes readiness/liveness probes use this endpoint
# ---------------------------------------------------------
@app.route("/health")
def health():
    return jsonify(
        {
            "status": "healthy",
            "environment": ENVIRONMENT,
            "version": APP_VERSION,
            "timestamp": datetime.now(timezone.utc).isoformat()
        }
    ), 200


# ---------------------------------------------------------
# Version endpoint
# Used to identify the exact deployed application version
# ---------------------------------------------------------
@app.route("/version")
def version():
    return jsonify(
        {
            "version": APP_VERSION,
            "environment": ENVIRONMENT
        }
    ), 200


# ---------------------------------------------------------
# Incident API
# ---------------------------------------------------------
@app.route("/api/incidents")
def incidents():
    return jsonify(
        {
            "environment": ENVIRONMENT,
            "version": APP_VERSION,
            "count": len(INCIDENTS),
            "incidents": INCIDENTS
        }
    ), 200


# ---------------------------------------------------------
# Azure Key Vault validation endpoint
# ---------------------------------------------------------
@app.route("/api/keyvault-check")
def keyvault_check():
    """
    Validate that the application can access Azure Key Vault
    through AKS Workload Identity.

    The secret value is intentionally NOT returned.
    """

    try:
        secret_value = get_key_vault_secret()

        logger.info(
            "Successfully accessed Key Vault secret '%s'",
            KEY_VAULT_SECRET_NAME
        )

        return jsonify(
            {
                "status": "success",
                "key_vault_access": True,
                "secret_name": KEY_VAULT_SECRET_NAME,
                "secret_loaded": bool(secret_value),
                "authentication": "AKS Workload Identity"
            }
        ), 200

    except Exception as exc:
        logger.exception("Failed to access Azure Key Vault")

        return jsonify(
            {
                "status": "error",
                "key_vault_access": False,
                "error_type": type(exc).__name__
            }
        ), 500


# ---------------------------------------------------------
# Run locally
# Production container uses Gunicorn from Dockerfile
# ---------------------------------------------------------
if __name__ == "__main__":
    app.run(
        host=os.getenv("FLASK_RUN_HOST", "127.0.0.1"),
        port=8080,
        debug=False
    )
