class CreateGenres < ActiveRecord::Migration[8.0]
  def change
    create_table :genres do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :genres, :slug
  end
end
