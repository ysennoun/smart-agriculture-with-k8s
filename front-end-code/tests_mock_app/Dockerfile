FROM python:3.7

WORKDIR /app
ENV PYTHONPATH /app

COPY requirements.txt ./
COPY app.py ./

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

CMD exec gunicorn --bind :5000 --workers 1 --threads 8 'app:app'

