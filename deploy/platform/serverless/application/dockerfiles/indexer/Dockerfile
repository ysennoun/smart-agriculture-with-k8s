FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app

COPY platform/serverless/requirements.txt ./
COPY platform/serverless/src/common /app/common
COPY platform/serverless/src/application/indexer /app/application/indexer

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD [ "python", "application/indexer/mqtt_main.py" ]