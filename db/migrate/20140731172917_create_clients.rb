class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.integer :client_number
      t.integer :bill_number

      t.timestamps
    end
  end
end
