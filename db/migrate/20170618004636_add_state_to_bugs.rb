class AddStateToBugs < ActiveRecord::Migration[5.0]
  def change
    add_column :bugs, :state, :string
  end
end
