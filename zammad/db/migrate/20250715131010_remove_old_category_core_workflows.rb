class RemoveOldCategoryCoreWorkflows < ActiveRecord::Migration[7.1]
  def up
    CoreWorkflow.where("name LIKE 'ops - category - % - visible options'").delete_all
    CoreWorkflow.where("name LIKE 'ops - subcategory - % - visible options'").delete_all
  end

  def down
    # no-op
  end
end
