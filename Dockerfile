# syntax=docker/dockerfile:1
# Prebuilt Canvas image (SWM-229): a pinned Canvas commit with its gems and
# compiled assets baked in, so a host only pulls and runs it. The database,
# uploads (/canvas/tmp/files) and first-run flags (/data) stay in volumes.

FROM ruby:3.4.1-bookworm AS base

RUN apt-get update && apt-get install -y \
    git curl build-essential \
    libpq-dev libxml2-dev libxslt1-dev \
    libidn11-dev shared-mime-info \
    zlib1g-dev libldap2-dev libsqlite3-dev libyaml-dev libxmlsec1-dev pkg-config \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20 + Yarn (Canvas requires node >=20)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler:2.4.19

ENV RAILS_ENV=development
WORKDIR /canvas


FROM base AS build

# Pinned Canvas LMS commit, so every build gets the same code. To upgrade,
# change this and rebuild; web runs db:migrate on its next start.
ARG CANVAS_REF=1c9f0bb8013ed69c4f2efe11fd483025469b7e6c

RUN git init -q . \
    && git fetch -q --depth 1 https://github.com/instructure/canvas-lms.git "$CANVAS_REF" \
    && git checkout -q FETCH_HEAD \
    && echo "$CANVAS_REF" > REVISION \
    && rm -rf .git

# Example configs, then the database and Redis wiring. The DB password stays
# in the environment (DB_PASSWORD, from .env); Rails evaluates the ERB at boot.
RUN for config in amazon_s3 delayed_jobs domain file_store outgoing_mail security external_migration dynamic_settings; do \
      cp "config/$config.yml.example" "config/$config.yml"; \
    done \
    && printf '%s\n' \
      'development:' \
      '  adapter: postgresql' \
      '  database: canvas_development' \
      '  host: db' \
      '  port: 5432' \
      '  username: canvas' \
      '  password: <%= ENV.fetch("DB_PASSWORD") %>' \
      '  timeout: 5000' > config/database.yml \
    && printf '%s\n' 'development:' '  url:' '  - redis://redis:6379' > config/redis.yml \
    && printf '%s\n' 'development:' '  cache_store: redis_cache_store' > config/cache_store.yml

RUN bundle install

RUN yarn install --pure-lockfile || yarn install --pure-lockfile --network-concurrency 1

# Brand configs live in the database, so web writes them at start instead.
# Node modules are only needed to compile, so they stay in this stage.
# Rails reads database.yml while compiling but never connects, so DB_PASSWORD
# is a placeholder here, not a secret.
RUN COMPILE_ASSETS_BRAND_CONFIGS=0 COMPILE_ASSETS_NPM_INSTALL=0 \
      DB_PASSWORD=not-used-at-build DISABLE_SPRING=1 \
      bundle exec rails canvas:compile_assets \
    && find . -name node_modules -type d -prune -exec rm -rf {} + \
    && rm -rf spec tmp/cache log/*.log


FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /canvas /canvas
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["/entrypoint.sh"]
