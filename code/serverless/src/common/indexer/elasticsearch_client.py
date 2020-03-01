import os
from elasticsearch import Elasticsearch
from ssl import create_default_context


def get_elasticsearch_endpoint() -> str:
    return os.environ["ELASTICSEARCH_ENDPOINT"]


def get_elasticsearch_ca_file() -> str:
    return os.environ["ELASTICSEARCH_CA_FILE"]


def get_elasticsearch_user() -> str:
    return os.environ["ELASTICSEARCH_USER"]


def get_elasticsearch_password() -> str:
    password_path = os.environ["ELASTICSEARCH_PASSWORD_PATH"]
    return open(password_path, 'r').read().rstrip('\n')


def get_elasticsearch_client() -> Elasticsearch:
    ca_file = get_elasticsearch_ca_file()
    context = create_default_context(cafile=ca_file)
    endpoint = get_elasticsearch_endpoint()
    user = get_elasticsearch_user()
    password = get_elasticsearch_password()
    return Elasticsearch(
        [endpoint],
        http_auth=(user, password),
        ssl_context=context,
    )