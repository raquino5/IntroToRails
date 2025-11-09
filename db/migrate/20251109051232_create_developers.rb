class CreateDevelopers < ActiveRecord::Migration[8.0]
  def change
    create_table :developers do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :developers, :slug
  end
end
