require 'base64'
require 'croupier'
require 'date'
require 'faker'
require 'json'
require 'kafka'
require 'slosilo'

class Animal
  def initialize(name=nil, species=nil, age=nil)
    @age_distribution = Croupier::Distributions.gamma(shape: 2.0, std: 2.0)
    @species_distribution = Croupier::Distributions.normal
    @species = species || random_species
    @age = age || random_age
    @name = name || case @species
                    when "dog"
                      Faker::Dog.name
                    when "cat"
                      Faker::Cat.name
                    end
  end
  def random_age
    @age_distribution.first.round(1)
  end
  def random_species
    n = @species_distribution.first
    case
    when n < 0
      "cat"
    when n >= 0
      "dog"
    end
  end
  def to_h
    return {
      name: @name,
      species: @species,
      age: @age
    }
  end
end

class Shelter
  def initialize(avg_animals_per_time_quantum=8)
    @surrender_distribution = Croupier::Distributions.poisson(lambda: avg_animals_per_time_quantum)
    kafka_url = ENV['KAFKA_ENDPOINT']
    kafka_servers = [kafka_url]
    puts "shelter: connecting to Kafka at #{kafka_servers}"
    kafka = Kafka.new kafka_servers, client_id: "secure-shelter"
    @producer = kafka.producer
    @day = DateTime.now

    @data_key = Base64.decode64(ENV['KAFKA_TOPIC_KEY'])[0..31]
    @topic = ENV['KAFKA_TOPIC']
  end
  def receive_animals number
    (1..number).each {
      @producer.produce(Base64.encode64(Slosilo::Symmetric.new.encrypt({
                                                         type: 'welcome',
                                                         date: @day.strftime('%Y-%b-%d'),
                                                         animal: Animal.new.to_h
                                                       }.to_json, key: @data_key)),
                        topic: @topic)
    }
    @producer.deliver_messages
  end
  def run_sync_forever
    while true
      count = @surrender_distribution.first.round(0)
      puts "shelter: received #{count} animals, notifying Kafka"
      receive_animals count
      puts "shelter: notify success, awaiting animals"
      @day += 1
      sleep 5
    end
  end
end

begin
  shelter = Shelter.new
  shelter.run_sync_forever
rescue SystemExit, Interrupt
  puts "shelter: Aborting"
  exit
end
