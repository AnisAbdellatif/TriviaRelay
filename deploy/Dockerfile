# The relay as an OTP release, with the built Flutter web app inside it.
#
# Build context is the repository root, because the image needs both `server/` and
# `app/build/web` (`scripts/ci.sh app` builds it, with CanvasKit bundled rather than
# fetched from a CDN; CI builds it and hands it over).
#
#   docker build -f deploy/Dockerfile -t trivia-relay .

ARG ELIXIR_IMAGE=hexpm/elixir:1.20.4-erlang-29.0.6-debian-trixie-20260824-slim
ARG RUNNER_IMAGE=debian:trixie-20260824-slim

FROM ${ELIXIR_IMAGE} AS builder

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential git \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

# Dependencies first, so editing application code doesn't recompile them.
# config.exs and prod.exs come along because `Application.compile_env` reads them.
COPY server/mix.exs server/mix.lock ./
RUN mix deps.get --only prod
COPY server/config/config.exs server/config/prod.exs config/
RUN mix deps.compile

COPY server/priv priv
COPY server/lib lib
RUN mix compile --warnings-as-errors

COPY server/config/runtime.exs config/
RUN mix release

FROM ${RUNNER_IMAGE}

RUN apt-get update -y \
  && apt-get install -y --no-install-recommends ca-certificates curl libncurses6 libstdc++6 locales openssl \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# No Erlang distribution. `bin/trivia_relay start` would otherwise open EPMD and a
# distribution port on every interface of the container, guarded only by the cookie
# `mix release` wrote into this image — readable by anyone who can pull it. Nothing
# here needs a second node; `bin/trivia_relay remote` does not work, by design.
ENV MIX_ENV=prod \
    RELEASE_DISTRIBUTION=none \
    RELEASE_TMP=/app/tmp \
    ERL_CRASH_DUMP=/app/tmp/erl_crash.dump \
    PHX_SERVER=true \
    PORT=4100 \
    WEB_DIR=/app/web

# The release and the web app belong to root and are only read by the relay, which runs
# as `nobody`: a bug in it can't rewrite its own code. The one place it writes is
# RELEASE_TMP, where the release puts the configuration runtime.exs makes at each boot.
WORKDIR /app
COPY --from=builder /src/_build/prod/rel/trivia_relay ./
COPY app/build/web ./web
RUN chmod -R go-w /app \
  && install -d -o nobody -g nogroup -m 700 /app/tmp

USER nobody
EXPOSE 4100

# Kamal refuses to deploy an image without its service's label (deploy/deploy.yml).
LABEL service="trivia-relay"

CMD ["/app/bin/trivia_relay", "start"]
