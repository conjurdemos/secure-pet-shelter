FROM ruby:2.5

RUN mkdir -p /opt/shelter
WORKDIR /opt/shelter

COPY Gemfile ./
RUN bundle install
COPY src ./src/

ENTRYPOINT ["/usr/local/bin/ruby", "/opt/shelter/src/shelter.rb"]
