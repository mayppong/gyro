FROM elixir:1.16-alpine

RUN apk --update add bash openssl nodejs npm inotify-tools \
  rm -rf /var/cache/apk/*

WORKDIR /gyro
ADD . /gyro

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix deps.get
