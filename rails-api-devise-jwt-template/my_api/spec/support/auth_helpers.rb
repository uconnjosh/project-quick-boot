module AuthHelpers
  def auth_headers_for(user)
    scope = :user
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, scope, nil)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure { |c| c.include AuthHelpers }
