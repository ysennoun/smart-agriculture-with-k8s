import json
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

    def get(self):
        return json.dumps({
            "device": self.device,
            "timestamp": str(self.timestamp),
            "temperature": self.temperature,
            "humidity": self.humidity,
            "moisture": self.moisture,
            "created_at": str(self.created_at) if self.created_at else None,
            "created_by": self.created_by,
            "updated_at": str(self.updated_at) if self.updated_at else None,
            "updated_by": self.updated_by
        })



