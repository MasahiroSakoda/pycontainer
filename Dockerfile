ARG BASE_IMAGE=python
ARG PYTHON_VERSION=3.11
ARG DISTRO_NAME=bookworm
ARG IMAGE_TAG=${PYTHON_VERSION}-slim-${DISTRO_NAME}

# -- Build Stage for base builder -----------
FROM ${BASE_IMAGE}:${IMAGE_TAG} AS builder
ARG WORKDIR=/app
ARG DEV_PACKAGES="build-essential"
ENV LANG=C.UTF-8 \
    TZ=Asia/Tokyo \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_VERSION=24.0 \
    POETRY_VERSION=1.7.1 \
    PYTHONPATH=${WORKDIR}

WORKDIR ${WORKDIR}
RUN apt-get -y update \
 && apt-get -y --no-install-recommends upgrade \
 && apt-get -y --no-install-recommends install \
 ${DEV_PACKAGES} \
 curl \
 git \
 && apt-get clean \
 && apt-get purge -y --auto-remove ${DEV_PACKAGES} \
 && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
 && git config --global --add safe.directory /app

COPY ./pyproject.toml ./poetry.lock* ./
RUN pip install --no-cache-dir --upgrade pip==${PIP_VERSION} \
 && pip install --no-cache-dir --upgrade poetry==${POETRY_VERSION} \
 && pip cache purge \
 && poetry config virtualenvs.create false \
 && poetry install --no-root --no-interaction --no-ansi \
 && poetry cache clear --all --no-interaction --no-ansi .

# -- Build Stage for Local Development -----------
FROM gcr.io/distroless/python3-debian12:debug AS dev
ARG GROUPNAME=nogroup
ARG USERNAME=nobody
ARG WORKDIR=/app

USER ${USERNAME}
WORKDIR ${WORKDIR}
COPY --chown=${USERNAME}:${GROUPNAME} --from=builder . ${WORKDIR}

# -- Build Stage for Production -----------
# FROM builder AS production
