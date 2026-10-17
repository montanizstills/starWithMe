FROM ruby:3.4.1-bookworm

RUN apt-get update && apt-get install -y \
    git curl build-essential \
    libpq-dev libxml2-dev libxslt1-dev \
    libidn11-dev shared-mime-info \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Node.js 18 + Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler:2.4.19

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000
WORKDIR /canvas
ENTRYPOINT ["/entrypoint.sh"]
