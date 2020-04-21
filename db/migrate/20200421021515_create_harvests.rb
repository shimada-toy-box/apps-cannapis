class CreateHarvests < ActiveRecord::Migration[6.0]
  def change
    create_table :harvests, id: :uuid do |t|
      t.references :integration, null: false, foreign_key: true, type: :uuid
      t.integer :batch_id
      t.string :vendor_id
      t.float :weight
      t.string :unit
      t.string :type
      t.datetime :harvested_at

      t.timestamps
    end

    add_index :harvests, :id, unique: true
    add_index :harvests, :batch_id
  end
end
