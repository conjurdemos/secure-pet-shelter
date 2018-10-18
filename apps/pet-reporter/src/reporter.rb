require 'base64'
require 'conjur-api'
require 'date'
require 'json'
require 'kafka'
require 'slosilo'

class Reporter
  def initialize
    kafka_url = ENV['KAFKA_ENDPOINT']
    kafka_servers = [kafka_url]
    puts "reporter: connecting to Kafka at #{kafka_servers}"
    @kafka = Kafka.new kafka_servers, client_id: "secure-reporter"
    @last_processed_message = 0

    conjur_account = ENV['CONJUR_ACCOUNT']
    conjur_username = ENV['CONJUR_AUTHN_LOGIN']
    conjur_api_key = ENV['CONJUR_AUTHN_API_KEY']
    data_key_id = ENV['REPORTER_DATA_KEY_ID']

    conjur = Conjur::API.new_from_key conjur_username, conjur_api_key
    id="#{conjur_account}:variable:#{data_key_id}"
    puts "fetching from Conjur: #{id}"
    @data_key = Base64.decode64(conjur.resource(id).value)[0..31]
    @crypto = Slosilo::Symmetric.new
  end
  def run_sync_forever
    @kafka.each_message(topic: 'pets') { |message|
      @last_processed_message = message.offset
      puts @crypto.decrypt(Base64.decode64(message.value), key: @data_key)
    }
  end
end

begin
  reporter = Reporter.new
  reporter.run_sync_forever
rescue SystemExit, Interrupt
  puts "reporter: Aborting"
  exit
end
