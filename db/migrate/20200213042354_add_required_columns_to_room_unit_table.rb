class AddRequiredColumnsToRoomUnitTable < ActiveRecord::Migration[5.2]
  def change
    add_column :room_units, :room_no, :string
  end
end
