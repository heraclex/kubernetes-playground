FROM apache/airflow:2.4.1
COPY requirements.txt .
USER root

# install these package `build-essential` `manpages-dev`
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y build-essential manpages-dev python3-dev libsasl2-dev iputils-ping telnet \
    && rm -rf /var/lib/apt/lists/*

# Adding the package path to local
ENV PATH $PATH:/opt/gcloud/google-cloud-sdk/bin 
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz \
    && mkdir -p /opt/gcloud \
    && tar -C /opt/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && /opt/gcloud/google-cloud-sdk/install.sh \
    && gcloud --version \
    && rm -f /tmp/google-cloud-sdk.tar.gz


USER airflow
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt