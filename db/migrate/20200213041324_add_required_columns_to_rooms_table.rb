class AddRequiredColumnsToRoomsTable < ActiveRecord::Migration[5.2]
  def change
    add_column :rooms, :is_master, :boolean
  end
end
