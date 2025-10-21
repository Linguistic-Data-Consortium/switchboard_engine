class CreateSpeakers < ActiveRecord::Migration[8.0]
  def change
    create_table :speakers do |t|
      t.string :filename
      t.string :channel
      t.string :sex
      t.integer :birth_year
      t.string :dialect_area
      t.integer :education
      t.string :topic_description

      t.timestamps
    end
  end
end
