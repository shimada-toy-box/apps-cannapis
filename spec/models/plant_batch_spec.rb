require 'rails_helper'

RSpec.describe PlantBatch, type: :model do
  it { should belong_to(:integration) }

  it { should validate_presence_of(:batch_id) }
  it { should validate_presence_of(:vendor_id) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:quantity) }
  it { should validate_presence_of(:type) }
end
