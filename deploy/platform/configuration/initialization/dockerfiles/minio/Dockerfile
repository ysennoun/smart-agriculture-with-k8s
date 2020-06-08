FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app


COPY platform/spark-jobs/target/spark-jobs-1.0-SNAPSHOT-jar-with-dependencies.jar ./
COPY platform/controllers/requirements.txt ./
COPY platform/controllers/src/common /app/common
COPY platform/controllers/src/initialization/minio /app/deployment/minio


RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD [ "python", "initialization/minio/put_jars_in_minio.py" ]