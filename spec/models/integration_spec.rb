require 'rails_helper'

RSpec.describe Integration, type: :model do
  it { should belong_to(:account) }
  it { should have_many(:transactions) }
  it { should have_many(:schedulers) }

  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:state) }
  it { should validate_presence_of(:vendor) }
  it { should validate_presence_of(:license) }
  it { should validate_presence_of(:facility_id) }
  it { should validate_presence_of(:eod) }
end
