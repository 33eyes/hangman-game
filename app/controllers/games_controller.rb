class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy]

  # GET /games
  # GET /games.json
  def index
    @games = Game.all
  end

  # GET /games/1
  # GET /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = Game.new
    
    # Find a new secret word that the user hasnt played yet
    @all_words = Word.pluck(:word)
    
    @user = User.find(params[:user_id])
    @user_games_words = @user.games.pluck(:secret_word)
    
    @all_words.each { |w|
      if !( @user_games_words.include? w )
        @new_secret_word = w
        break
      end
    }
    
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games
  # POST /games.json
  def create
    # Get the current user
    @user = User.find( params[:user_id] )
  
    # Find a new secret word that the user hasnt played yet
    @all_words = Word.pluck(:word)
    @user_games_words = @user.games.pluck(:secret_word)
    @all_words.each { |w|
      if !( @user_games_words.include? w )
        @new_secret_word = w
        break
      end
    }
    
    @game = Game.new
    @game.user_id = params[:user_id]
    @game.secret_word = @new_secret_word
     
    @guessed_letter_a = params[:guessed_letter_a]
    @guessed_letter_b = params[:guessed_letter_b]
    @guess_whole_word = params[:guess_whole_word].downcase
     
    if @guessed_letter_a == 'A'
        @game.letters_guessed = "a"
    elsif @guessed_letter_b == 'B'
        @game.letters_guessed = "b"
    elsif !(@guess_whole_word.blank?)
      # Guessing the whole word on the 1st try
      @game.letters_guessed = ""
      if @guess_whole_word == @game.secret_word
        @game.outcome = 1
      else
        @game.outcome = 0
      end
    end
     
    if @game.save
      flash[:notice] = "You won!" if @game.outcome == 1
      flash[:alert] = "You lost!" if @game.outcome == 0
      redirect_to user_game_path( params[:user_id], @game.id )
    else
      flash[:alert] = "Something went wrong. Let's try again."
      render action: :new
    end
    
    #respond_to do |format|
    #  if @game.save
    #    format.html { redirect_to @game, notice: 'Game was successfully created.' }
    #    format.json { render :show, status: :created, location: @game }
    #  else
    #    format.html { render :new }
    #    format.json { render json: @game.errors, status: :unprocessable_entity }
    #  end
    #end
  end

  # PATCH/PUT /games/1
  # PATCH/PUT /games/1.json
  def update
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: 'Game was successfully updated.' }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1
  # DELETE /games/1.json
  def destroy
    @game.destroy
    respond_to do |format|
      format.html { redirect_to games_url, notice: 'Game was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def game_params
      params.permit(:user_id, :guessed_letter_a, :guessed_letter_b, :guess_whole_word)
    end
end
