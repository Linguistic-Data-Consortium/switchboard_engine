class CreateSegments < ActiveRecord::Migration[8.0]
  def change
    create_table :segments do |t|
      t.string :filename
      t.string :channel
      t.float :beg
      t.float :end
      t.integer :turn
      t.text :text

      t.timestamps
    end
  end
end
