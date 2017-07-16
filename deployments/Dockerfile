FROM elixir:1.3

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /gyro
ADD . /gyro

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
RUN mix deps.get

RUN curl -sL https://deb.nodesource.com/setup_7.x | bash -
RUN apt-get update && \
  apt-get install -qqy nodejs
