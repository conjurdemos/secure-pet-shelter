require 'base64'
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

    @data_key = Base64.decode64(ENV['KAFKA_TOPIC_KEY'])[0..31]
    @crypto = Slosilo::Symmetric.new
    @topic = ENV['KAFKA_TOPIC']
  end
  def run_sync_forever
    @kafka.each_message(topic: @topic) { |message|
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
