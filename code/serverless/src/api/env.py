import os


def get_es_alias_raw_data():
    return os.environ["ES_ALIAS_RAW_DATA"]


def get_es_alias_summarized_data():
    return os.environ["ES_ALIAS_SUMMARIZED_DATA"]
