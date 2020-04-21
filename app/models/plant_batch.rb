class PlantBatch < ApplicationRecord
  belongs_to :integration

  validates :batch_id, :status, :name, :vendor_id, :type, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
