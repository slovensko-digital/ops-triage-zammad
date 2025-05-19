class AddOpsIssueIdentifier < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'ops_issue_identifier',
      display: 'ID dopytu na portáli',
      data_type: 'input',
      data_option: {
        default: '',
        type: 'text',
        maxlength: 10,
        linktemplate: "",
        null: true,
        options: {},
        relation: ''
      },
      active: true,
      screens: {
        create_middle: {
          'ticket.agent' => { shown: false }
        },
        edit: {
          'ticket.agent' => { shown: false }
        },
      },
      position: 103,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'ops_issue_identifier')
    ObjectManager::Attribute.migration_execute
  end
end
