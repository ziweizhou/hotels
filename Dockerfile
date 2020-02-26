FROM ruby:2.6.5
ENV AIRHOST_DIR="/airhost-hotels"
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client
RUN mkdir $AIRHOST_DIR
WORKDIR $AIRHOST_DIR
COPY Gemfile $AIRHOST_DIR/Gemfile
COPY Gemfile.lock $AIRHOST_DIR/Gemfile.lock
RUN bundle install
COPY . $AIRHOST_DIR

# Add a script to be executed every time the container starts.
RUN chmod +x bin/*
RUN ls -al bin/*
EXPOSE 3000

# Start the main process.
CMD ["bin/start"]