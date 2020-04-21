FactoryBot.define do
  factory :harvest do
    integration

    sequence(:batch_id) { |n| n }
    sequence(:vendor_id) { |n| n }
    weight { Faker::Number.decimal(l_digits: 2) }
    unit { Faker::Measurement.weight(amount: :none) }
    type { :plant }
    harvested_at { Faker::Date.between(from: 2.days.ago, to: Date.today) }
  end
end
