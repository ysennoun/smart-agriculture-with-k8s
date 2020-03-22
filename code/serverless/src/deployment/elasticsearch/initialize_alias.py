import os
from typing import List
from common.utils.logger import Logger
from common.utils.date import get_current_date_as_string
from common.storage.elasticsearch_client import get_elasticsearch_client


logger = Logger().get_logger()
DATE_FORMAT = "%Y-%m-%d"


def get_es_alias_list() -> List[str]:
    return os.environ["ES_ALIAS_LIST"].split(",")


def create_alias(es_client, alias_list: List[str]):
    logger.info("Start create alias")
    for alias in alias_list:
        logger.info(f"Check for alias", extra={"alias": alias})
        if not es_client.indices.exists_alias(name=alias):
            index = f"{alias}-{get_current_date_as_string(date_format=DATE_FORMAT)}"
            es_client.indices.create(index=index)
            es_client.indices.put_alias(index=index, name=alias)
            logger.info(f"Create alias", extra={"alias": alias, "index": index})
    logger.info("End create alias")


if __name__ == "__main__":
    try:
        logger.info("Intialize Alias")
        es_client = get_elasticsearch_client()
        es_alias_list = get_es_alias_list()
        create_alias(es_client, es_alias_list)
    except Exception as ex:
        logger.error(f"Create Elasticsearch Indexed failed", extra={"exception": str(ex)})
