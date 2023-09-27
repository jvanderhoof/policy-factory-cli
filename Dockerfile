# Dockerfile.rails
FROM ruby:3.2 AS rails-toolbox

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH

COPY Gemfile Gemfile.lock ./
COPY Rakefile ./opt/app
COPY lib ./lib
RUN gem install rails bundler

RUN bundle

#RUN chown -R user:user /opt/app
WORKDIR /opt/app

# Run a shell
CMD ["/bin/bash"]