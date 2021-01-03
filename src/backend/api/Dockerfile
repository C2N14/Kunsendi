FROM python:3.8-slim

RUN python -m pip install --upgrade pip

WORKDIR /usr/src/app

COPY  . .

RUN python -m pip install -r requirements.txt

ENV FLASK_DEBUG 1
ENV FLASK_ENV development

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN python -m pip install debugpy
