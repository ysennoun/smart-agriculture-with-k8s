import os
from elasticsearch import Elasticsearch


def get_elasticsearch_endpoint() -> str:
    return os.environ["ELASTICSEARCH_ENDPOINT"]


def get_elasticsearch_client() -> Elasticsearch:
    return Elasticsearch(get_elasticsearch_endpoint())