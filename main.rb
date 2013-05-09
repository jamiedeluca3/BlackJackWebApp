require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

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
    card_total -= 10 if card_total > BLACKJACK_AMOUNT
  end

  # Return card total
  card_total
  end  

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"

  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @winner = "<strong>#{session[:player_name]} tie's the dealer!</strong> #{msg}"
  end

end

# Before methods means run this block of code before any of the other actions
before do
  @show_hit_or_stay_buttons = true
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
  session[:player_name] = nil
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :welcome
end

post '/welcome' do
  if params[:player_name].nil? || params[:player_name].empty?
    @error = "Name can't be blank"
    halt erb(:welcome)
  end

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot].to_i
    @error = "Bet amount cannot be greater than $#{session[:player_pot]}."
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
      
end

get '/game' do
  session[:turn] = session[:player_name]

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

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack!")
  elsif calculate_total(session[:player_cards]) > BLACKJACK_AMOUNT
    loser!("Sorry, #{session[:player_name]} busted at #{player_total}.")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Sorry, dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT  #17, 18, 19, 20
    # Dealer stays
    redirect '/game/compare'
  else
    # Dealer hits
    @show_dealer_hit_button = true
  end
  
  erb :game, layout: false
end

post '/game/dealer/hit' do
  # Deal dealer card
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end