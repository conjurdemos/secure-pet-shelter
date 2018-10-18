require 'base64'
require 'conjur-api'
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

    conjur_account = ENV['CONJUR_ACCOUNT']
    conjur_username = ENV['CONJUR_AUTHN_LOGIN']
    conjur_api_key = ENV['CONJUR_AUTHN_API_KEY']
    data_key_id = ENV['SHELTER_DATA_KEY_ID']

    conjur = Conjur::API.new_from_key conjur_username, conjur_api_key
    @data_key = Base64.decode64(conjur.resource("#{conjur_account}:variable:#{data_key_id}").value)[0..31]
  end
  def receive_animals number
    (1..number).each {
      @producer.produce(Base64.encode64(Slosilo::Symmetric.new.encrypt({
                                                         type: 'welcome',
                                                         date: @day.strftime('%Y-%b-%d'),
                                                         animal: Animal.new.to_h
                                                       }.to_json, key: @data_key)),
                        topic: 'pets')
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
