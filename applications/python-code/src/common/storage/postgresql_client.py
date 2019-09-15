import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base


class PostgreSQLClient:
    class __PostgreSQLClient:
        def __init__(self):
            user = os.environ["POSTGRES_USER"]
            password = os.environ["POSTGRES_PASSWORD"]
            host = os.environ["POSTGRES_HOST"]
            port = os.environ["POSTGRES_PORT"]
            database = os.environ["POSTGRES_DATABASE"]
            url = f'postgres://{user}:{password}@{host}:{port}/{database}'
            print(url)
            self.engine = create_engine(url)
            self.session = sessionmaker(bind=self.engine)()
            self.Base = declarative_base()

        def __str__(self):
            return repr(self) + str(self.session)

    instance = None

    def __init__(self):
        if not self.instance:
            self.instance = {
                "engine": PostgreSQLClient.__PostgreSQLClient().engine,
                "session": PostgreSQLClient.__PostgreSQLClient().session,
                "Base": PostgreSQLClient.__PostgreSQLClient().Base
            }
            print(self.instance)

    def __getattr__(self, name):
        return getattr(self.instance, name)

    def get_engine(self):
        return self.instance["engine"]

    def get_session(self):
        return self.instance["session"]

    def get_base(self):
        return self.instance["Base"]