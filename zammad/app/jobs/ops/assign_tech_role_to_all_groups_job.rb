class Ops::AssignTechRoleToAllGroupsJob < ApplicationJob
  def perform
    ops_tech_account_role = Role.find_by(name: 'Portal Tech Account')
    ops_tech_account_role.groups = Group.all
    ops_tech_account_role.save!
  end
end
