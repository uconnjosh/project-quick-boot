Rails.application.routes.draw do
  namespace :api do
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
end
