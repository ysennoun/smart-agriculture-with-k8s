FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app

COPY platform/controllers/requirements.txt ./
COPY platform/controllers/src/common /app/common
COPY platform/controllers/src/indexer /app/indexer

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD [ "python", "indexer/mqtt_main.py" ]