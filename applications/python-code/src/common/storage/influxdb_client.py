import os
from influxdb import InfluxDBClient


class InfluxDBIoTClient:
    class __InfluxDBIoTClient:
        def __init__(self):
            user = os.environ["INFLUXDB_USER"]
            password = os.environ["INFLUXDB_USER_PASSWORD"]
            host = os.environ["INFLUXDB_HOST"]
            port = int(os.environ["INFLUXDB_PORT"])
            self.database = os.environ["INFLUXDB_DB"]
            self.client = InfluxDBClient(host, port, user, password, self.database)
            self.client.create_database(self.database)

        def __str__(self):
            return repr(self) + str(self.client)

    instance = None

    def __init__(self):
        if not self.instance:
            self.instance = self.__InfluxDBIoTClient().client

    def __getattr__(self, name):
        return getattr(self.instance, name)

    def get_client(self):
        return self.instance
