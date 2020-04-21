require 'rails_helper'

RSpec.describe Harvest, type: :model do
  it { should belong_to(:integration) }

  it { should validate_presence_of(:batch_id) }
  it { should validate_presence_of(:vendor_id) }
  it { should validate_presence_of(:unit) }
  it { should validate_presence_of(:weight) }
  it { should validate_presence_of(:type) }
end
