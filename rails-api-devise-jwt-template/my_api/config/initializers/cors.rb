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
