FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app

COPY platform/controllers/requirements.txt ./
COPY platform/controllers/src/common /app/common
COPY platform/controllers/src/api /app/api

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD exec gunicorn --access-logfile - --certfile=/etc/ssl/api/tls.crt --keyfile=/etc/ssl/api/tls.key --ssl-version TLS --bind :443 --workers 1 --threads 8 'api.api_main:create_app()'
