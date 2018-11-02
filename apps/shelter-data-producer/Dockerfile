FROM ruby:2.5

#---install summon and summon-conjur---#
ENV CONJUR_MAJOR_VERSION=5
ENV CONJUR_VERSION=5
RUN curl -sSL https://raw.githubusercontent.com/cyberark/summon/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash && \
    curl -sSL https://raw.githubusercontent.com/cyberark/summon-conjur/master/install.sh \
      | env TMPDIR=$(mktemp -d) bash
# as per https://github.com/cyberark/summon#linux
# and    https://github.com/cyberark/summon-conjur#install
ENV PATH="/usr/local/lib/summon:${PATH}"

#---install shelter application---#
RUN mkdir -p /opt/shelter
WORKDIR /opt/shelter

COPY Gemfile ./
RUN bundle install
COPY secrets.yml ./
COPY src ./src/

ENTRYPOINT ["/usr/local/bin/summon", "/usr/local/bin/ruby", "/opt/shelter/src/shelter.rb"]
