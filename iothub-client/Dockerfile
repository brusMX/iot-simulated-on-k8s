# IoT Hub requires python-dev libraries which at the time being are not available in apt get after 3.4
FROM python:3.4
RUN git clone --recursive https://github.com/Azure/azure-iot-sdk-python.git 
RUN apt-get update && \
    apt-get install -y \
    python3-dev \
    git \
    cmake \
    build-essential \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    uuid-dev \
    sudo && rm -rf /var/lib/apt/lists/*
# After we have all the dependencies we can set up the environment and compile the solution    
WORKDIR azure-iot-sdk-python/build_all/linux
RUN ./setup.sh --python-version 3.4
RUN ./build.sh --build-python 3.4
# Add the client to the current python3.4 site-packages install (Someone with more python exp should suggest a workaround)
RUN cp /azure-iot-sdk-python/c/cmake/iotsdk_linux/python/src/iothub_client.so /usr/local/lib/python3.4/site-packages