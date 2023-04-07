# syntax=docker/dockerfile:1.4
FROM python:3.8.13-slim-bullseye AS build

ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV PYTHONUNBUFFERED 1
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8


# Specify label-schema specific arguments and labels.
ARG BUILD_DATE
ARG VCS_REF

# coincurve requires libgmp
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -qqy --assume-yes --no-install-recommends \
        apt-utils \
        gcc \
        git \
        libc6-dev \
        libc-dev \
        libssl-dev \
        libgmp-dev; \
    apt-get clean; \
	rm -rf /var/lib/apt/lists/*; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark;

WORKDIR /code
COPY . .

# force repository to be clean so the version string is right
RUN git reset --hard

# Using "test" optional to include test dependencies in built docker-image
RUN pip install --no-cache-dir .[test] && \
    apt-get purge -y -qq --auto-remove -o APT::AutoRemove::RecommendsImportant=false;


ENTRYPOINT ["/usr/local/bin/vyper"]
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Vyper" \
      org.label-schema.description="Vyper is an experimental programming language" \
      org.label-schema.url="https://vyper.readthedocs.io/en/latest/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vyperlang/vyper" \
      org.label-schema.vendor="Vyper Team" \
      org.label-schema.schema-version="1.0"


FROM gcr.io/distroless/python3-debian11:nonroot AS final

COPY --link --chmod=0744 --from=build /usr/local/bin/vyper /usr/local/bin/vyper
ENTRYPOINT ["/usr/local/bin/vyper"]
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Vyper" \
      org.label-schema.description="Vyper is an experimental programming language" \
      org.label-schema.url="https://vyper.readthedocs.io/en/latest/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/vyperlang/vyper" \
      org.label-schema.vendor="Vyper Team" \
      org.label-schema.schema-version="1.0"
