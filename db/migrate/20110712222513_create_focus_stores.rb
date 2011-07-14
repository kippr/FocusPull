class CreateFocusStores < ActiveRecord::Migration
  def self.up
    create_table :focus_stores do |t|
      t.string :username
      t.text :focus

      t.timestamps
    end
  end

  def self.down
    drop_table :focus_stores
  end
end
