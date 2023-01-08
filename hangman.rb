# frozen_string_literal: true

require 'net/http'
require 'json'

# holds the state of the game, saved to a file for the beginning of each loop
class GameState
  def initialize(word, concealed_word, tries)
    @word = word
    @concealed_word = concealed_word
    @tries = tries
  end
  
  def to_json(*_args)
    { 'word': @word, 'concealed_word': @concealed_word, 'tries': @tries }
  end
end

# the hangman game
class Hangman
  def initialize
    @word = JSON.parse(Net::HTTP.get(URI('https://random-word-api.herokuapp.com/word')))[0]
    @concealed_word = '_' * @word.length
    @tries = 5
    @win = false
  end

  def run
    load if File.exist? './save_file.json'
    puts 'Welcome to Rubyman, a hangman game built in ruby!'
    while @tries != 0 || @win.eql?(true)

      puts "You have #{@tries} tries"
      # check if user has won
      won?
      puts "Guess a letter: #{@concealed_word}"
      @current_guess = gets.chomp
      # check if the letter is valid and matches
      check_letter
      save
    end
    puts "Sorry you lost, the word was #{@word}" if @win.eql?(false)
    File.delete('./save_file.json')
    puts 'Thanks for playing!'
  end

  def won?
    return if @concealed_word.include?('_')

    puts "You have won with #{@tries} left"
    @win = true
  end

  def check_letter
    # check to ensure the guess is valid
    return if @current_guess.length > 1

    # subtract a try if nothing matches
    if !@word.include?(@current_guess)
      @tries -= 1
    else
      @word.split('').each_with_index { |char, index| @concealed_word[index] = char if char == @current_guess }
    end
  end
  
  def save
    game_state = GameState.new(@word, @concealed_word, @tries)
    # save the last state of the game
    File.open('./save_file.json', 'w+') do |file|
      file.puts JSON.generate(game_state.to_json)
    end
  end

  def load
    puts 'loading previous game'
    game_state = JSON.load_file('./save_file.json')
    @word = game_state['word']
    @concealed_word = game_state['concealed_word']
    @tries = game_state['tries']
  end
end

Hangman.new.run
