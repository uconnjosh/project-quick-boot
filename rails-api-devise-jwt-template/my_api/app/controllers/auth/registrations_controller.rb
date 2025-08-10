class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, :name, :organization_name)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: { user: resource.as_json(only: [:id, :email, :name, :organization_name]) }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
