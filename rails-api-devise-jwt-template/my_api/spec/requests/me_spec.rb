require "rails_helper"

RSpec.describe "GET /me", type: :request do
  it "requires auth" do
    get "/me"
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns current user when authorized" do
    user = create(:user, email: "a@b.com", password: "password123")
    get "/me", headers: auth_headers_for(user)
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).dig("user","email")).to eq("a@b.com")
  end
end
