json.array!(@games) do |game|
  json.extract! game, :id, :secret_word, :user_id, :outcome, :letters_guessed
  json.url game_url(game, format: :json)
end
