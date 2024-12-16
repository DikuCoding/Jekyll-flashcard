require 'dotenv/load'
require 'trello'
require 'yaml'
require 'fileutils'

module Jekyll
  class ContentCreatorGenerator < Generator
    safe true

    def setup
      @trello_api_key = ENV['TRELLO_API_KEY']
      @trello_token = ENV['TRELLO_TOKEN']

      Trello.configure do |config|
        config.developer_public_key = @trello_api_key
        config.member_token = @trello_token
      end
    end

    def generate(site)
      setup

      # Fetch Trello cards
      list_id = "675a7f9ea1657613864ffc50" # Replace with your actual list ID
      cards = Trello::List.find(list_id).cards

      # Paths for flashcards and posts
      flashcards_file = File.join(site.source, '_data', 'flashcards.yml')
      posts_dir = File.join(site.source, '_posts')

      # Load existing flashcards data
      flashcards = File.exist?(flashcards_file) ? YAML.load_file(flashcards_file) : { 'flashcards' => [] }
      existing_flashcards = flashcards['flashcards']

      # Track updated flashcards
      updated_flashcards = []

      # Process each card from Trello
      cards.each do |card|
        labels = card.labels.map(&:color)
        next unless labels.include?("green") # Process only cards with "green" labels

        due_on = card.due&.to_date.to_s
        slug = card.name.split.join("-").downcase
        created_on = DateTime.strptime(card.id[0..7].to_i(16).to_s, '%s').to_date.to_s
        article_date = due_on.empty? ? created_on : due_on
        post_filename = "#{article_date}-#{slug}.md"
        post_filepath = File.join(posts_dir, post_filename)

        # Check if card already exists in flashcards.yml
        existing_card = existing_flashcards.find { |f| f['front'] == card.name }

        # Create or update flashcard and post
        updated_flashcards << {
          'title' => card.name,
          'description' => card.desc
        }

        # If the card is new or has been updated
        if existing_card.nil? || existing_card['back'] != card.desc
          content = <<~POST
            ---
            layout: post
            title: #{card.name}
            date: #{article_date}
            ---
            #{card.desc}
          POST

          # Write or overwrite the post file
          File.open(post_filepath, 'w+') { |f| f.write(content) }
        end
      end

      # Remove deleted flashcards and posts
      existing_flashcards.each do |existing_card|
        next if updated_flashcards.any? { |f| f['front'] == existing_card['front'] }

        # Remove the corresponding post file
        slug = existing_card['title'].split.join("-").downcase
        post_filename = "#{existing_card['date']}-#{slug}.md"
        post_filepath = File.join(posts_dir, post_filename)

        FileUtils.rm(post_filepath) if File.exist?(post_filepath)
      end

      # Update flashcards.yml
      flashcards['flashcards'] = updated_flashcards
      File.open(flashcards_file, 'w') { |f| f.write(flashcards.to_yaml) }
    end
  end
end
