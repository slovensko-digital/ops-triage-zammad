class CreateOpsOwnerHandoverRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :ops_owner_handover_runs do |t|
      t.string :step, null: false, limit: 20
      t.references :old_owner, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :new_owner, foreign_key: { to_table: :users, on_delete: :cascade }
      t.json :groups
      t.string :status, null: false, default: 'queued', limit: 20
      t.text :log, null: false, default: ''
      t.text :error
      t.datetime :started_at
      t.datetime :finished_at
      t.references :created_by, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.timestamps null: false
    end
    add_index :ops_owner_handover_runs, :status
  end
end
