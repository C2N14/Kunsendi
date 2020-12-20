FROM python:3.8-slim

RUN python -m pip install --upgrade pip

WORKDIR /kunsendi

COPY  . .

RUN python -m pip install -r requirements.txt

ARG DEBUG
ARG ENV_TYPE

ENV FLASK_DEBUG=${DEBUG}
ENV FLASK_ENV=${ENV_TYPE}

# check for debug env var to install debugging tools
RUN if [ ${DEBUG} = "1" ]; then python -m pip install debugpy; fi
