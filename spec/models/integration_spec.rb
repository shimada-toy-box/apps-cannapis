require 'rails_helper'

RSpec.describe Integration, type: :model do
  it { should belong_to(:account) }
  it { should have_many(:transactions) }
  it { should have_many(:schedulers) }
  it { should have_many(:plant_batches) }
  it { should have_many(:harvests) }

  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:facility_id) }
  it { should validate_presence_of(:vendor) }
  it { should validate_presence_of(:eod) }

  describe '#vendor_id' do
    let(:integration) { create(:integration) }
    subject { integration.vendor_id }

    it { is_expected.to eq(integration.license) }
  end
end
