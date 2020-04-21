FactoryBot.define do
  factory :plant_batch do
    integration

    sequence(:batch_id) { |n| n }
    sequence(:vendor_id) { |n| n }
    name { Faker::Alphanumeric.unique.alphanumeric(number: 24) }
    type { Faker::Alphanumeric.new }
    quantity { Faker::Number.within(range: 1..100) }
    status { :active }
    modified_at { Faker::Date.between(from: 7.days.ago, to: Date.today) }
  end
end
