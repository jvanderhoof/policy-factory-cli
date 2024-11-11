# Dockerfile.rails
FROM ruby:3.2

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.5

RUN bundle install
# --without development test

WORKDIR $INSTALL_PATH

# Run a shell
CMD ["/bin/bash"]
