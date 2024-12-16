# require 'dotenv/load'
# require 'trello'
# require 'yaml'

# #Configure Trello API

# Trello.configure do |config|
#   config.developer_public_key = ENV['TRELLO_API_KEY']
#   config.member_token = ENV['TRELLO_TOKEN']
# end

# list_id = "675a7f9ea1657613864ffc50"

# #Fetch cards from the specified list

# begin
#   list = Trello::List.find(list_id)
#   cards = list.cards

#   #Prepare data for Jekyll
#   data = {"flashcards" => cards.map {
#     |card| {
#       "title" => card.name,
#       "description" => card.desc,
#           }
#     }}

#   #Write to a yml file in the _data directory
#   File.write("_data/flashcards.yml", data.to_yaml)
#   puts "Flashcards data fetched and saved to _data/flashcards.yml"

# rescue => e
#   puts "An error occurred #{e.message}"
# end
