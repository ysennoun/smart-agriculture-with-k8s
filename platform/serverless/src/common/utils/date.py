from datetime import date, datetime

DEFAULT_DATE_FORMAT = "%Y-%m-%dT%H:%M:%SZ"


def get_current_date(date_format: str = DEFAULT_DATE_FORMAT) -> str:
    return f"{datetime.now():{date_format}}"


def get_date_at_midnight(date_format: str = DEFAULT_DATE_FORMAT) -> str:
    date_today = date.today()
    date_at_midnight = datetime.combine(date_today, datetime.min.time())
    return f"{date_at_midnight:{date_format}}"
