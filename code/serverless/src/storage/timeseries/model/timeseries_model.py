from common.utils.date import get_current_date_as_string


_MEASUREMENT = "smart_agriculture"


def get_points_to_insert(data: dict) -> list:
    return [
        {
            "measurement": _MEASUREMENT,
            "tags": {
                "host": "k8s",
                "region": "eu-west"
            },
            "time": get_current_date_as_string(),
            "fields":  data
        }
    ]
