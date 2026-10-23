FROM ruby:3.4.1-bookworm

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

# Keep bundler config, plugins (bundler-multilock) and gems in the canvas-src volume
# so every container sharing it (web, jobs) sees the same bundle.
ENV BUNDLE_APP_CONFIG=/canvas/.bundle \
    BUNDLE_PATH=/canvas/vendor/bundle

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000
WORKDIR /canvas
ENTRYPOINT ["/entrypoint.sh"]
