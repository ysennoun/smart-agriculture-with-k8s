from indexer import env
from common.utils.logger import Logger
from common.utils.date import get_current_date_as_string

logger = Logger().get_logger()


class DeviceHandler:

    DATE_FORMAT = "%Y-%m-%d"

    def __init__(self, mqtt_client, es_client, es_alias):
        self.mqtt_client = mqtt_client
        self.es_client = es_client
        self.es_alias = es_alias

    def index(self, body: str):
        es_index = self.es_alias + "-" + get_current_date_as_string(date_format=self.DATE_FORMAT)
        self.es_client.indices.put_alias(index=es_index, name=self.es_alias, ignore=[400, 404])
        return self.es_client.index(index=es_index, body=body)

    def handle_on_message(self, payload: str, topic):
        logger.info(f"message {str(payload)} from topic {topic}")
        self.index(str(payload))
        logger.info("end on_message")

    def on_connect(self, client, userdata, flags, rc):
        logger.info(f"Connected with result code {str(rc)}")
        client.subscribe(env.get_topic_name())

    def on_message(self, client, userdata, msg):
        payload = str(msg.payload.decode("utf-8"))
        self.handle_on_message(payload, msg.topic)

    def run(self):
        self.mqtt_client.on_connect = self.on_connect
        self.mqtt_client.on_message = self.on_message

        service_name = env.get_service_name()
        namespace_name = env.get_namespace_name()
        host = env.get_host(service_name, namespace_name)
        port = env.get_port()
        keep_alive = env.get_keep_alive()
        self.mqtt_client.connect(host, port, keep_alive)
        self.mqtt_client.loop_forever()
