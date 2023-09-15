# Dockerfile.rails
FROM ruby:3.2 AS rails-toolbox

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH

COPY Gemfile Gemfile.lock ./
RUN gem install rails bundler

RUN bundle

#RUN chown -R user:user /opt/app
WORKDIR /opt/app

# Run a shell
CMD ["/bin/bash"]
