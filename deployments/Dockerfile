FROM elixir:1.5-alpine

WORKDIR /gyro
ADD . /gyro

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix archive.install --force https://github.com/phoenixframework/archives/raw/master/phoenix_new.ez
RUN mix deps.get
