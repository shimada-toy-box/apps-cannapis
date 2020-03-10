require 'rails_helper'
require 'ostruct'

RSpec.describe MetrcService::Package::Harvest do
  METRC_API_KEY = ENV['METRC_SECRET_CA'] unless defined?(METRC_API_KEY)

  def load_response_json(path)
    File.read("spec/support/data/#{path}.json")
  end

  let(:integration) { create(:integration, state: 'ca') }
  let(:facility_id) { 2 }
  let(:batch_id) { 374 }

  let(:ctx) do
    {
      'id': '2365',
      'type': 'completions',
      'attributes': {
        'id': 2365,
        'user_id': 20,
        'content': nil,
        'start_time': '2020-02-24T05:00:00.000Z',
        'end_time': '2020-02-24T05:00:00.000Z',
        'occurrence': 0,
        'action_type': 'harvest',
        'options': {
          'resources': [
            {
              'resource_unit_id': 26,
              'generated_quantity': 100
            }
          ],
          'harvest_type': 'complete',
          'note_content': '',
          'harvest_unit_id': 12,
          'seeding_unit_id': 11,
          'quantity_remaining': 1,
          'calculated_quantity': 1.0
        }
      },
      'relationships': {
        'action_result': {
          'meta': {
            'included': false
          }
        },
        'batch': {
          'data': {
            'id': '374',
            'type': 'batches'
          }
        },
        'facility': {
          'data': {
            'id': 2,
            'type': 'facilities'
          }
        },
        'user': {
          'data': {
            'id': 20,
            'type': 'users'
          }
        }
      }
    }.with_indifferent_access
  end

  let(:transaction) { stub_model Transaction, type: :harvest_package_batch, success: false }

  before do
    allow_any_instance_of(described_class)
      .to receive(:get_transaction)
      .and_return(transaction)
  end

  context '#call' do
    subject { described_class.call(ctx, integration) }

    describe 'on an old successful transaction' do
      before do
        transaction.success = true
      end

      it { is_expected.to eq(transaction) }
    end

    describe 'with corn crop' do
      include_examples 'with corn crop'
    end

    describe 'on a complete harvest' do
      let(:expected_payload) do
        [
          Tag: 'asdfasdfasdfasdf123123123',
          Room: 'Warehouse',
          Item: 'Buds',
          UnitOfWeight: 'g of Bulk Flower - 5th Element',
          PatientLicenseNumber: nil,
          Note: nil,
          IsProductionBatch: false,
          ProductionBatchNumber: nil,
          IsTradeSample: false,
          ProductRequiresRemediation: false,
          RemediateProduct: false,
          RemediationMethodId: nil,
          RemediationDate: nil,
          RemediationSteps: nil,
          ActualDate: '2020-02-24T05:00:00.000Z',
          Ingredients: [
            {
              HarvestId: 374,
              HarvestName: 'Feb24-5th-Ele-Can-2',
              Weight: 100,
              UnitOfWeight: 'g of Bulk Flower - 5th Element'
            }
          ]
        ]
      end

      let(:testing) { true }

      before do
        stub_request(:get, "#{ENV['ARTEMIS_BASE_URI']}/api/v3/facilities/#{facility_id}")
          .to_return(body: load_response_json('api/package/facility'))

        stub_request(:get, "#{ENV['ARTEMIS_BASE_URI']}/api/v3/facilities/#{facility_id}/batches/#{batch_id}?include=zone,barcodes,custom_data,seeding_unit,harvest_unit,sub_zone")
          .to_return(body: load_response_json("api/package/batch#{testing ? '-testing' : ''}"))

        stub_request(:get, "#{ENV['ARTEMIS_BASE_URI']}/api/v3/facilities/#{facility_id}/resource_units/26")
          .to_return(body: load_response_json('api/package/resource_unit'))

        stub_request(:post, "https://sandbox-api-ca.metrc.com/packages/v1/create#{testing ? '/testing' : ''}?licenseNumber=LIC-0001")
          .with(body: expected_payload.to_json, basic_auth: [METRC_API_KEY, integration.secret])
          .to_return(status: 200, body: '', headers: {})
      end

      context 'standard package' do
        it { is_expected.to eq(transaction) }
        it { is_expected.to be_success }
      end

      context 'testing package' do
        let(:testing) { true }
        it { is_expected.to eq(transaction) }
        it { is_expected.to be_success }
      end
    end
  end
end
