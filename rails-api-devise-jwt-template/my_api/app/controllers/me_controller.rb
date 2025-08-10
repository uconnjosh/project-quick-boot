class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: { user: current_user.as_json(only: [:id, :email]) }
  end
end
