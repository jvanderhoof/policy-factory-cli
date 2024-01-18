# Dockerfile.rails
FROM ruby:3.2 AS rails-toolbox

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH

COPY Gemfile Gemfile.lock ./
RUN gem install rails bundler:2.5

RUN bundle

WORKDIR $INSTALL_PATH

# Run a shell
CMD ["/bin/bash"]
