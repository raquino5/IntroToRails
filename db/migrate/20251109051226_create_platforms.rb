class CreatePlatforms < ActiveRecord::Migration[8.0]
  def change
    create_table :platforms do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :platforms, :slug
  end
end
