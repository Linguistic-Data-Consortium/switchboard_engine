# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t ua20250501 .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name ua20250501 ua20250501

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.3
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

### more
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends apt-transport-https netcat-openbsd libpq5 libpq-dev unzip
RUN curl -sL https://deb.nodesource.com/setup_21.x | bash -
RUN apt-get update -yqq && apt-get install -yqq --no-install-recommends nodejs

# use bun instead of node
RUN curl -fsSL https://bun.sh/install | bash
ENV BUN_INSTALL="/root/.bun"
ENV PATH="$BUN_INSTALL/bin:$PATH"
# end base


# Throw-away build stage to reduce size of final image
### build stage was broken up into gem, lock, bundled, and build stages
FROM base AS gem
# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY lib/switchboard_engine/version.rb ./lib/switchboard_engine/
COPY Gemfile Gemfile.lock switchboard_engine.gemspec ./
# end gem


### when changing the Gemfile, target lock in the compose file
FROM gem AS lock
RUN bundle install
RUN bundle lock --add-platform x86_64-linux
# end lock


FROM gem AS bundled
# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# end bundled


FROM bundled AS build
# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile
# end build


### create a dev version
FROM bundled AS dev
# ENTRYPOINT ["./docker-entrypoint.sh"]
# ENTRYPOINT ["/rails/bin/docker-entrypoint"]
WORKDIR /rails/test/dummy
CMD ["bin/rails", "s", "-b", "0.0.0.0"]
#CMD ["sleep", "300"]
# end dev


