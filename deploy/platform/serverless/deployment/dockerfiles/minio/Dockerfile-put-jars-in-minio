FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app


COPY platform/historical-jobs/target/historical-jobs-1.0-SNAPSHOT-jar-with-dependencies.jar ./
COPY platform/serverless/requirements.txt ./
COPY platform/serverless/src/common /app/common
COPY platform/serverless/src/deployment/minio /app/deployment/minio


RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD [ "python", "deployment/minio/put_jars_in_minio.py" ]