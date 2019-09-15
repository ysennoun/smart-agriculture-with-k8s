from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime
from common.storage.postgresql_client import PostgreSQLClient

Base = PostgreSQLClient().get_base()


class LastValueModel(Base):
    __tablename__ = 'lastvalue'

    id = Column(Integer, primary_key=True, nullable=False, autoincrement=True)
    device = Column(String(250), primary_key=True, unique=True)
    timestamp = Column(DateTime, nullable=False)
    temperature = Column(Float, nullable=False)
    humidity = Column(Float, nullable=False)
    moisture = Column(Float, nullable=False)

    created_at = Column(DateTime, default=datetime.utcnow)
    created_by = Column(String(250), default=None)
    updated_at = Column(DateTime, default=datetime.utcnow)
    updated_by = Column(String(250), default=None)



