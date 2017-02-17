class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    @users_w_game_counts = User.select("users.*, COUNT(games.id) as games_count").joins("LEFT OUTER JOIN games ON (games.user_id = users.id)")
    .where("games.outcome = 1")
    .group("users.id")
    .order("games_count DESC")
    .limit(10)
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])
    
    # Look at the games the user played 
    @user_games = @user.games.where(outcome: [0, 1]).order(created_at: :desc)
    @user_wins = @user.games.where("outcome = 1")
    
    @user_games_count = @user_games.length
    @user_wins_count = @user_wins.length
    @user_success_ratio = (( @user_wins_count * 1.00) / @user_games_count * 100).round()
    
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:name, :email)
    end
end
