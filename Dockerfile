ARG BASE_IMAGE=python
ARG PYTHON_VERSION=3.11
ARG DISTRO_NAME=bookworm
ARG IMAGE_TAG=${PYTHON_VERSION}-slim-${DISTRO_NAME}

# -- Build Stage for base builder -----------
FROM ${BASE_IMAGE}:${IMAGE_TAG} AS builder
ENV LANG=C.UTF-8 \
    TZ=Asia/Tokyo \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_VERSION=23.2.1 \
    POETRY_VERSION=1.7.0
WORKDIR /app

ARG DEV_PACKAGES="build-essential"
RUN apt-get -y update \
 && apt-get -y --no-install-recommends upgrade \
 && apt-get -y --no-install-recommends install ${DEV_PACKAGES} curl git \
 && apt-get clean \
 && apt-get purge -y --auto-remove ${DEV_PACKAGES} \
 && rm -rf /var/lib/apt/lists/* \
 && git config --global --add safe.directory /app

COPY ./pyproject.toml ./poetry.lock* ./
RUN pip install --no-cache-dir --upgrade pip==${PIP_VERSION} \
 && pip install --no-cache-dir --upgrade poetry==${POETRY_VERSION} \
 && poetry config virtualenvs.create true \
 && poetry config virtualenvs.in-project true \
 && poetry install \
 && chown -R user /home/user/.cache/pypoetry /app/.venv

# -- Build Stage for Local Development -----------
FROM gcr.io/distroless/python3-debian12:debug
WORKDIR /app
COPY --chown=user:user --from=builder /app .

# -- Build Stage for Production -----------
# FROM builder AS production
