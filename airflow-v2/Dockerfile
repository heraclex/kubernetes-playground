# Dockerfile, only used for local development
FROM apache/airflow:2.3.1-python3.8
USER root
RUN apt-get update \
    && apt-get install -y gcc \
    && rm -rf /var/lib/apt/lists/*
USER airflow
# install Python requirements, of not required
COPY requirements.txt .
RUN pip3 install --user -r requirements.txt
COPY dags dags