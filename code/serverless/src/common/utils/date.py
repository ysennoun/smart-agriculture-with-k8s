from datetime import datetime, timedelta

DEFAULT_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


def get_current_date_as_string(date_format: str=DEFAULT_DATE_FORMAT) -> str:
    return f"{datetime.now():{date_format}}"


def get_current_timestamp() -> int:
    return int(datetime.now().timestamp())


def get_past_timestamp(days: int = 7) -> int: # by default it is 7 days
    return int(datetime.now().timestamp() - timedelta(days=days).total_seconds())
