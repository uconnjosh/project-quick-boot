#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:-my_api}"
RAILS_VERSION="${RAILS_VERSION:-8.0.2}"
RUBY_VERSION="${RUBY_VERSION:-3.2.0}"

echo "Creating Rails API app: $APP_NAME (Rails $RAILS_VERSION, Ruby $RUBY_VERSION)"

# Pre-flight checks
if ! command -v rails >/dev/null 2>&1; then
  echo "Rails not found. Install Rails ($RAILS_VERSION) and retry." >&2
  exit 1
fi

# Create app
rails _${RAILS_VERSION}_ new "$APP_NAME" --api -T -d postgresql
cd "$APP_NAME"

# Ruby version pin
echo "$RUBY_VERSION" > .ruby-version

# Gemfile additions
cat >> Gemfile <<'RUBY'

# --- Auth ---
gem "devise"
gem "devise-jwt" # stateless tokens

# --- CORS ---
gem "rack-cors"

# --- Security (optional) ---
gem "secure_headers"

group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end
RUBY

bundle install

# RSpec
bin/rails generate rspec:install

# Devise install + User
bin/rails generate devise:install
# Devise mailer host for API dev
ruby -i -pe 'gsub(/# config\.action_mailer\.default_url_options = .+$/, "config.action_mailer.default_url_options = { host: \"localhost\", port: 3000 }")' config/environments/development.rb
bin/rails generate devise User

# JWT denylist model
bin/rails generate model JwtDenylist jti:string:index exp:datetime
bin/rails db:migrate

# JwtDenylist model
cat > app/models/jwt_denylist.rb <<'RUBY'
class JwtDenylist < ApplicationRecord
end
RUBY

# User model modules
# Note: this step skipped, configure mannally in editor
# ruby -i -pe 'gsub(/devise :database_authenticatable.*$/,
# "devise :database_authenticatable, :registerable, :recoverable, :validatable, :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist,")' app/models/user.rb
# class User < ApplicationRecord
#   # Include default devise modules. Others available are:
#   # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
#   devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :jwt_authenticatable,
#          jwt_revocation_strategy: JwtDenylist
# end

# CORS initializer
mkdir -p config/initializers
cat > config/initializers/cors.rb <<'RUBY'
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # TODO: restrict in production (e.g., origins \"https://your-frontend.example\")
    origins "*"
    resource "*",
      headers: :any,
      expose: ["Authorization"],
      methods: %i[get post put patch delete options head]
  end
end
RUBY

# Secure headers initializer (optional; safe defaults)
cat > config/initializers/secure_headers.rb <<'RUBY'
SecureHeaders::Configuration.default do |config|
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0"
  config.referrer_policy = "strict-origin-when-cross-origin"
end
RUBY

# Devise config: navigational formats + JWT
ruby -i -pe 'gsub(/^# config\.navigational_formats = .+$/, "config.navigational_formats = []")' config/initializers/devise.rb

awk '1; /Devise\.setup do \|config\|/ && !x {print "\n  # JWT for API-only apps\n  # Set a strong secret in ENV[\"DEVISE_JWT_SECRET\"]. On Rails 8 you may need eager route loading in tests.\n  config.jwt do |jwt|\n    jwt.secret = ENV.fetch(\"DEVISE_JWT_SECRET\") { \"dev-secret-change-me\" }\n    jwt.dispatch_requests = [\n      [\"POST\", %r{^/auth/sign_in$}],\n      [\"POST\", %r{^/auth/sign_up$}]\n    ]\n    jwt.revocation_requests = [\n      [\"DELETE\", %r{^/auth/sign_out$}]\n    ]\n    jwt.expiration_time = 2.weeks.to_i\n    jwt.request_formats = { user: [:json] }\n  end\n"; x=1}' config/initializers/devise.rb > /tmp/devise.rb && mv /tmp/devise.rb config/initializers/devise.rb

# Auth controllers
bin/rails g controller auth/registrations --no-helper --no-assets
cat > app/controllers/auth/registrations_controller.rb <<'RUBY'
class Auth::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: { user: resource.as_json(only: [:id, :email]) }, status: :created
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
RUBY

bin/rails g controller auth/sessions --no-helper --no-assets
cat > app/controllers/auth/sessions_controller.rb <<'RUBY'
class Auth::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: { user: resource.as_json(only: [:id, :email]) }, status: :ok
  end

  def respond_to_on_destroy
    head :no_content
  end
end
RUBY

# Protected example controller
bin/rails g controller me --no-helper --no-assets
cat > app/controllers/me_controller.rb <<'RUBY'
class MeController < ApplicationController
  before_action :authenticate_user!

  def show
    render json: { user: current_user.as_json(only: [:id, :email]) }
  end
end
RUBY

# Routes
cat > config/routes.rb <<'RUBY'
Rails.application.routes.draw do
  devise_for :users,
    path: "auth",
    path_names: {
      sign_in: "sign_in",
      sign_out: "sign_out",
      registration: "sign_up"
    },
    controllers: {
      sessions: "auth/sessions",
      registrations: "auth/registrations"
    }

  get "/health", to: proc { [200, { "Content-Type" => "application/json" }, [ { ok: true }.to_json ]] }
  get "/me", to: "me#show"
end
RUBY

# RSpec helpers
mkdir -p spec/support spec/factories spec/requests

cat > spec/support/auth_helpers.rb <<'RUBY'
module AuthHelpers
  def auth_headers_for(user)
    scope = :user
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, scope, nil)
    { "Authorization" => "Bearer #{token}" }
  end
end

RSpec.configure { |c| c.include AuthHelpers }
RUBY
# require support files
ruby -i -pe 'gsub(/^# Dir\[Rails\.root\.join\("spec\/support\/\*\*\/\*\.rb"\)\].*$/, "Dir[Rails.root.join(\"spec/support/**/*.rb\")].sort.each { |f| require f }")' spec/rails_helper.rb
ruby -i -pe 'gsub(/^# config\.include FactoryBot::Syntax::Methods$/, "config.include FactoryBot::Syntax::Methods")' spec/rails_helper.rb

# factories
cat > spec/factories/users.rb <<'RUBY'
FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
  end
end
RUBY

# request spec
cat > spec/requests/me_spec.rb <<'RUBY'
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
RUBY

echo "✅ All set. Next:"
echo "  1) export DEVISE_JWT_SECRET=\$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')"
echo "  2) cd $APP_NAME && bin/rails s"


# do this instead of step1:
# ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
# # put the value into: bin/rails credentials:edit
# # devise_jwt_secret: <PASTE_HEX>

