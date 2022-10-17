FROM apache/airflow:2.4.1
COPY requirements.txt .
USER root
# install these package `build-essential` `manpages-dev`
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y build-essential manpages-dev python3-dev libsasl2-dev iputils-ping telnet \
    && rm -rf /var/lib/apt/lists/*
USER airflow
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt