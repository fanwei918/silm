class CreateCraftCrafts < ActiveRecord::Migration
  def self.up
    create_table :craft_crafts do |t|
      # t.column :name, :string
    end
  end

  def self.down
    drop_table :craft_crafts
  end
end
