class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :game, null: false, foreign_key: true
      t.string :author
      t.text :content
      t.string :source
      t.integer :rating

      t.timestamps
    end
  end
end
