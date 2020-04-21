class CreatePlantBatches < ActiveRecord::Migration[6.0]
  def change
    create_table :plant_batches, id: :uuid do |t|
      t.references :integration, null: false, foreign_key: true, type: :uuid
      t.integer :batch_id
      t.string :vendor_id
      t.string :name
      t.string :type
      t.integer :quantity, default: 0
      t.string :status, null: false, default: :active
      t.datetime :modified_at

      t.timestamps
    end

    add_index :plant_batches, :id, unique: true
    add_index :plant_batches, :batch_id
  end
end
