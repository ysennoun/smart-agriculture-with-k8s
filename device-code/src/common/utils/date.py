from datetime import datetime

DEFAULT_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


def get_current_date(date_format: str = DEFAULT_DATE_FORMAT) -> str:
    return f"{datetime.now():{date_format}}"