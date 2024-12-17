require 'dotenv/load'
require 'trello'
require 'yaml'
require 'date'

Trello.configure do |config|
  config.developer_public_key = ENV['TRELLO_API_KEY']   
  config.member_token = ENV['TRELLO_TOKEN']      
end

class TrelloFlashcardGenerator
  FLASHCARD_FILE = '_data/flashcards.yml'
  POSTS_FOLDER = '_posts'

  def initialize(board_id)
    @board_id = board_id
    @flashcards_data = { 'flashcards' => [] }
    @categories = {}
  end

  def fetch_trello_cards
    board = Trello::Board.find(@board_id)
    board.cards.each do |card|
      process_card(card)
    end
    save_flashcards
    create_post_files
  end

  private

  def process_card(card)
    title = card.name
    description = card.desc || "No description provided."
    label_color = fetch_label_color(card)

    # Organize cards by label color
    @categories[label_color] ||= []
    @categories[label_color] << { 'title' => title, 'description' => description }

    # Add to flashcards.yml format
    @flashcards_data['flashcards'] << { 'title' => title, 'description' => description, 'category' => label_color }
  end

  def fetch_label_color(card)
    card.labels.any? ? card.labels.first.color || 'none' : 'none'
  end

  def save_flashcards
    File.open(FLASHCARD_FILE, 'w') { |file| file.write(@flashcards_data.to_yaml) }
  end

  def create_post_files
    @categories.each do |category, cards|
      category_name = category || 'uncategorized'
      cards.each do |card|
        create_post_file(category_name, card)
      end
    end
  end

  def create_post_file(category, card)
    post_name = "#{Date.today}-#{card['title'].downcase.gsub(' ', '-')}.md"
    post_content = <<~POST
      ---
      layout: post
      title: "#{card['title']}"
      category: "#{category}"
      ---
      #{card['description']}
    POST

    File.open(File.join(POSTS_FOLDER, post_name), 'w') { |file| file.write(post_content) }
  end
end

# Run the Generator
generator = TrelloFlashcardGenerator.new('l8O34Xpg') # Replace with your Trello Board ID
generator.fetch_trello_cards
