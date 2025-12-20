class StatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @months = params[:months]&.to_i || 6
    @months = [ 3, 6, 12, 18, 24 ].include?(@months) ? @months : 6
  end
end
