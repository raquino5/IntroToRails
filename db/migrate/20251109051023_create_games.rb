class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.integer :rawg_id
      t.string :name
      t.date :released
      t.decimal :rating, precision: 3, scale: 1
      t.string :slug
      t.integer :steam_appid
      t.text :description

      t.timestamps
    end
    add_index :games, :slug
  end
end
