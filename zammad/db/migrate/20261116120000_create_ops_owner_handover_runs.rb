# The owner handover runs queued from the admin page /ops/owner_handover (Ops::OwnerHandoverRun).
class CreateOpsOwnerHandoverRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :ops_owner_handover_runs do |t|
      t.string :step, null: false, limit: 20
      t.string :old_owner_email, null: false
      t.string :new_owner_email
      t.json :groups
      t.string :status, null: false, default: 'queued', limit: 20
      t.text :log, null: false, default: ''
      t.text :error
      t.datetime :run_at, null: false
      t.datetime :started_at
      t.datetime :finished_at
      t.integer :created_by_id, null: false
      t.timestamps null: false
    end
    add_index :ops_owner_handover_runs, :status
  end
end
