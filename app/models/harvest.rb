class Harvest < ApplicationRecord
  belongs_to :integration

  validates :batch_id, :unit, :weight, :vendor_id, :type, presence: true
  validates :weight, presence: true, numericality: { greater_than: 0 }
end
