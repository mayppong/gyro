FROM elixir:1.7-alpine

RUN apk --update add bash openssl && \
  rm -rf /var/cache/apk/*

WORKDIR /gyro
ADD . /gyro

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
