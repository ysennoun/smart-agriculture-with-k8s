import os


ENVIRONMENT = os.environ["ENVIRONMENT"]
MQTT_SERVICE_NAME = f"smart-agriculture-infrastructure-vernemq.{ENVIRONMENT}"
API_SERVICE_NAME = f"ingress.{ENVIRONMENT}"
