FROM ruby:2.5

RUN mkdir -p /opt/reporter
WORKDIR /opt/reporter

COPY Gemfile ./
RUN bundle install
COPY src ./src/

ENTRYPOINT ["/usr/local/bin/ruby", "/opt/reporter/src/reporter.rb"]
