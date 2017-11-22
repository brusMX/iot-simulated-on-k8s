FROM brusmx/iot-hub-python-sdk:1.0
# For this example our work directory will be /sender
WORKDIR /sender
# You must set these variables to the container
ENV CONNECTION_STRING='' \
    DEVICE_ID='' 
# Now we copy our script
COPY /sender/send.py /sender/send.py
COPY /sender/pythonpath.py /sender/pythonpath.py
# Remember that Entrypoint only works when you do docker run, not docker build
ENTRYPOINT ["python","/sender/send.py"]