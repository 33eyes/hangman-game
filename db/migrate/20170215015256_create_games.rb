class CreateGames < ActiveRecord::Migration[5.0]
  def change
    create_table :games do |t|
      t.string :secret_word
      t.integer :user_id
      t.integer :outcome
      t.string :letters_guessed

      t.timestamps
    end
  end
end
