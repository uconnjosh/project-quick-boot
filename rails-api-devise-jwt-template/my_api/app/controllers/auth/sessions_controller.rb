class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end

  def respond_with(resource, _opts = {})
    render json: { 
      email: resource.email,
      name: resource.name,
      organization_name: resource.organization_name,
      token: resource.current_jwt_token
    }, status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end
end
