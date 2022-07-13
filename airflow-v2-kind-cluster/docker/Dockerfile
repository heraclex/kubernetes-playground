FROM apache/airflow:2.3.1-python3.8
COPY requirements.txt .
USER root
RUN apt-get update \
    && apt-get install -y gcc iputils-ping telnet \
    && rm -rf /var/lib/apt/lists/*
USER airflow
RUN pip install --upgrade pip
RUN pip install -r requirements.txt