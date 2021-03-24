# Gyro
[![Build Status](https://travis-ci.org/mayppong/gyro.png)](https://travis-ci.org/mayppong/gyro)
[![Test Workflow](https://github.com/mayppong/gyro/actions/workflows/test.yaml/badge.svg)](https://github.com/mayppong/gyro/actions/workflows/test.yaml)

Gyro is an Elixir clone of shawarmaspin that [@whiterook6](http://github.com/whiterook6) started. The goal of the project is to implement shawarmaspin with scalability and efficiency in mind. The application doesn't actually do any intensive operations. So instead of being performant, Gyro should be easily scaled and support as many users as possible on hardware with as little resources as possible. The plan for production deployment is to rely on the cheapest DigitalOcean droplet box ($5/month) and add more cheap boxes to the network cluster as needed.


## Running

To start the app:

  1. Install dependencies with `mix deps.get` and `npm install`.
  2. Start Phoenix endpoint with `mix phoenix.server`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Testing

To run the unit tests:

  1. Install dependencies with `mix deps.get`.
  2. Run `mix test`.

The general benchmark of the application is done by stress-testing using [tsung](http://tsung.erlang-projects.org/). Of which, the config file for it is included in the `./test` folder of the project.


## Contribute

We are looking for contributors, and there are many ways you can contribute. If you are looking to get some hands on, please feel free to pick up tickets, and submit pull requests! Otherwise, submitting tickets for any issues or improvements would be appreciated.
