require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do
  def calculate_total(cards)
    # Get card value from the second element [1] and put into new array
    temp_array = cards.map {|card_value| card_value[1]}

    # Loop through the temp array and calculate card total
    card_total = 0
    temp_array.each do |value|
    if value == "A"
      card_total += 11
    elsif value.to_i == 0 # J, Q, K
      card_total += 10
    else
      card_total += value.to_i
    end
  end

  # If total is greater than 21 & the card is an ace, set ace value 1
  temp_array.select{|e| e == "A"}.count.times do
    card_total -= 10 if card_total > 21
  end

  # Return card total
  card_total
  end  
end

get '/simpleroute' do
  "This is the most simple route ever created."
end

get '/test_template' do
  erb :testtemplate
end

get '/nested_template' do
  erb :"/nested_template/nested_template"
end

get '/form' do
  erb :form
end

get '/' do
  if params[:player_name].nil? || params[:player_name].empty?
    redirect '/welcome'
  else
    redirect '/game'
  end
end

get '/welcome' do
  erb :welcome
end

post '/welcome' do
  if params[:player_name].nil? || params[:player_name].empty?
    @error = "Name can't be blank"
    halt erb(:welcome)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # Create deck
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']

  # Shuffle ceck
  session[:deck] = suits.product(values).shuffle!

  # Deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  erb :game
end
