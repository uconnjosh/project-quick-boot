# Rails API + Devise + JWT Template (Rails 8.0.2 / Ruby 3.2.0)

A reproducible starter to spin up a Rails **API-only** app with Devise and `devise-jwt`, plus CORS, a protected `/me` endpoint, and RSpec.

## Quick start

```bash
# requires: Ruby 3.2.0, Rails 8.0.2, PostgreSQL
git clone <your-repo-url>.git rails-api-devise-jwt-template
cd rails-api-devise-jwt-template

# pick a name for your app
export APP_NAME=my_api

# generate the app and wire everything up
bash bootstrap.sh

# run it
cd "$APP_NAME"
bin/rails db:prepare
bin/rails s
```

### Auth flow (curl)

```bash
# Sign up
curl -X POST http://localhost:3000/auth/sign_up   -H "Content-Type: application/json"   -d '{"user":{"email":"josh@example.com","password":"password123","password_confirmation":"password123"}}' -i

# Copy the 'Authorization: Bearer <JWT>' from the response headers

# Sign in
curl -X POST http://localhost:3000/auth/sign_in   -H "Content-Type: application/json"   -d '{"user":{"email":"josh@example.com","password":"password123"}}' -i

# Hit protected endpoint
curl http://localhost:3000/me -H "Authorization: Bearer <JWT>"

# Sign out (revokes the token)
curl -X DELETE http://localhost:3000/auth/sign_out -H "Authorization: Bearer <JWT>" -i
```

## What you get

- Rails API mode (Postgres)
- Devise + devise-jwt (denylist strategy)
- CORS (exposes `Authorization` header)
- RSpec + factories + request spec example
- `/health`, `/me` and auth endpoints (`/auth/sign_in`, `/auth/sign_up`, `/auth/sign_out`)

## Notes

- The JWT secret is read from `ENV["DEVISE_JWT_SECRET"]`. For development: `export DEVISE_JWT_SECRET=$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')`.
- This template targets Rails **8.0.2** and Ruby **3.2.0** by default.
- On Rails 8, if you run into lazy route loading issues in tests with Devise, see comments in `config/initializers/devise.rb` and consider requiring mappings early.
