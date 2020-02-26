class AddRequiredColumnsToHousesTable < ActiveRecord::Migration[5.2]
  def change
    add_column :houses, :is_master, :boolean
    add_column :houses, :status, :string
    add_column :houses, :address, :string
  end
end
