FactoryBot.define do
  factory :jwt_denylist do
    jti { "MyString" }
    exp { "2025-08-09 17:33:45" }
  end
end
