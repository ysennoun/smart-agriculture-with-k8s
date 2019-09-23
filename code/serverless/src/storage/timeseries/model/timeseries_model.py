from datetime import datetime


_MEASUREMENT = "smart_agriculture"


def get_points_to_insert(data: dict) -> list:
    return [
        {
            "measurement": _MEASUREMENT,
            "tags": {
                "host": "k8s",
                "region": "eu-west"
            },
            "time": f"{datetime.now():%Y-%m-%dT%H:%M:%SZ}",
            "fields":  data
        }
    ]