class OpsAddResponsibleSubjectChangedAtToTickets < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'responsible_subject_changed_at',
      display: 'Posledná zmena zodpovedného subjektu',
      data_type: 'datetime',
      data_option: {
        future: true,
        past: true,
        diff: nil,
        default: nil,
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
          'ticket.agent' => { shown: true }
        },
      },
      position: 23,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'responsible_subject_changed_at',
    )

    ObjectManager::Attribute.migration_execute
  end
end
