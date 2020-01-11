import os


ENVIRONMENT = os.environ["ENVIRONMENT"]
MQTT_SERVICE_NAME = f"{ENVIRONMENT}-smart-agriculture-infrastructure-vernemq"
API_SERVICE_NAME = f"{ENVIRONMENT}-ingress"
