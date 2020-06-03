FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app

COPY platform/serverless/requirements.txt ./
COPY platform/serverless/src/common /app/common
COPY platform/serverless/src/application/back_end /app/application/back_end

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD exec gunicorn --access-logfile - --certfile=/etc/ssl/back-end/tls.crt --keyfile=/etc/ssl/back-end/tls.key --ssl-version TLS --bind :443 --workers 1 --threads 8 'application.back_end.back_end_main:create_app()'
