class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!
  before_action :only_current_user
  before_action :user_needs_name

  # GET /games
  # GET /games.json
  def index
    @games = Game.all
  end

  # GET /games/1
  # GET /games/1.json
  def show
    @user = User.find( params[:user_id] )
    @game = @user.games.find( params[:id] )
    gallows_calc
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

    if @new_secret_word.blank?
        redirect_to user_path( params[:user_id] )
    end

  end

  # GET /games/1/edit
  def edit
    @user = User.find( params[:user_id] )
    @game = @user.games.find( params[:id] )
    gallows_calc
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

    @guess_whole_word = params[:guess_whole_word].downcase
    ("a".."z").each { |letter| 
      @game.letters_guessed = params["guessed_letter_" + letter] if !( params["guessed_letter_" + letter].blank? )
    }

    if ( @game.letters_guessed.blank? && !(@guess_whole_word.blank?) )
      # Guessing the whole word on the 1st try
      @game.letters_guessed = ""
      if @guess_whole_word == @game.secret_word
        @game.outcome = 1
      else
        @game.outcome = 0
      end
    end

    if @game.save
      if ( (@game.outcome == 1) || (@game.outcome == 0) )
        # If the game is over
        flash[:notice] = "You won!" if @game.outcome == 1
        flash[:alert] = "You lost!" if @game.outcome == 0
        redirect_to user_game_path( params[:user_id], @game.id )
      else
        # If the game is not over yet
        redirect_to edit_user_game_path( params[:user_id], @game.id )
      end
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

    @user = User.find( params[:user_id] )
    @game = @user.games.find( params[:id] )

    # Process guesses
    @guess_whole_word = params[:guess_whole_word].downcase

    @new_letter_guess = ''
    ("a".."z").each { |letter| 
      @new_letter_guess = params["guessed_letter_" + letter] if !( params["guessed_letter_" + letter].blank? )
    }
    
    if ( @new_letter_guess.blank? && !(@guess_whole_word.blank?) )
      # Guessing the whole word
      if @guess_whole_word == @game.secret_word
        @game.outcome = 1
      else
        @game.outcome = 0
      end
    end

    if !( (@game.outcome == 1) || (@game.outcome == 0) )
      # Calculate new game outcome (0, 1, or nil)
      @game.letters_guessed = '' if @game.letters_guessed.nil?
      @game.letters_guessed = @game.letters_guessed + @new_letter_guess

      @lguesses = @game.letters_guessed.downcase
      @correct_guesses_num = 0
      @secret_word_unique_letters_count = 0
      @game.secret_word.split('').each_with_index { |ch, ind|
        if !( @game.secret_word.split('').take(ind).include? ch )
          if @lguesses.include? ch
            @correct_guesses_num = @correct_guesses_num + 1
          end
          @secret_word_unique_letters_count = @secret_word_unique_letters_count + 1
        end
      }

      # Did user guess all letters of secret word?
      if @correct_guesses_num == @secret_word_unique_letters_count
        # Won game, b/c user guessed all letters of secret word
        @game.outcome = 1
      else
        # Are there 10 wrong guesses?
        @wrong_guesses_num = @lguesses.length - @correct_guesses_num
        if @wrong_guesses_num >= 10
          # Lost game, b/c there are 10 wrong guesses
          @game.outcome = 0
        else
          # Neither lost nor won yet
          @game.outcome = nil
        end
      end
    end

    if @game.update_attributes(:outcome => @game.outcome, :letters_guessed => @game.letters_guessed)
      if ( (@game.outcome == 1) || (@game.outcome == 0) )
        # If the game is over
        flash[:notice] = "You won!" if @game.outcome == 1
        flash[:alert] = "You lost!" if @game.outcome == 0
        redirect_to user_game_path( params[:user_id], @game.id )
      else
        # If the game is not over yet
        redirect_to edit_user_game_path( params[:user_id], @game.id )
      end
    else
      flash[:alert] = "Something went wrong. Let's try again."
      render action: :edit
    end

    #respond_to do |format|
    #  if @game.update(game_params)
    #    format.html { redirect_to @game, notice: 'Game was successfully updated.' }
    #    format.json { render :show, status: :ok, location: @game }
    #  else
    #    format.html { render :edit }
    #    format.json { render json: @game.errors, status: :unprocessable_entity }
    #  end
    #end
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
      params.permit(:user_id, :guessed_letter_a, :guessed_letter_b,
      :guessed_letter_c, :guessed_letter_d,
      :guessed_letter_e, :guessed_letter_f,
      :guessed_letter_g, :guessed_letter_h,
      :guessed_letter_i, :guessed_letter_j,
      :guessed_letter_k, :guessed_letter_l,
      :guessed_letter_m, :guessed_letter_n,
      :guessed_letter_o, :guessed_letter_p,
      :guessed_letter_q, :guessed_letter_r,
      :guessed_letter_s, :guessed_letter_t,
      :guessed_letter_u, :guessed_letter_v,
      :guessed_letter_w, :guessed_letter_x,
      :guessed_letter_y, :guessed_letter_z,
      :guess_whole_word)
    end

    def only_current_user
      @user = User.find( params[:user_id] )
      redirect_to(root_url) unless @user == current_user
    end

    def user_needs_name
      redirect_to(edit_user_path(current_user)) if current_user.name.blank?
    end
    
    def gallows_calc
      @game.letters_guessed = '' if @game.letters_guessed.nil?
      @lguesses = @game.letters_guessed.downcase
  
      # Calculate wrong guesses count for gallows diagram
      @correct_guesses_num = 0
      @game.secret_word.split('').each_with_index { |ch, ind|
        if !( @game.secret_word.split('').take(ind).include? ch )
          if @lguesses.include? ch
            @correct_guesses_num = @correct_guesses_num + 1
          end
        end
      }
      @wrong_guesses_num = @lguesses.length - @correct_guesses_num
    end
end
