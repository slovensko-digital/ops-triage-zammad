class AddCitizenAndResponsibleSubjectLastContactAt < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    unless ObjectManager::Attribute.exists?(object_lookup_id: 1, name: 'citizen_last_contact_at')
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'citizen_last_contact_at',
        display: __('Posledný kontakt občana'),
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
          create_middle: { 'ticket.agent' => { shown: false } },
          edit: { 'ticket.agent' => { shown: true } }
        },
        position: 306,
        created_by_id: 1,
        updated_by_id: 1
      )
    end

    unless ObjectManager::Attribute.exists?(object_lookup_id: 1, name: 'responsible_subject_last_contact_at')
      ObjectManager::Attribute.add(
        object: 'Ticket',
        name: 'responsible_subject_last_contact_at',
        display: __('Posledný kontakt zodpovedného subjektu'),
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
          create_middle: { 'ticket.agent' => { shown: false } },
          edit: { 'ticket.agent' => { shown: true } }
        },
        position: 307,
        created_by_id: 1,
        updated_by_id: 1
      )
    end

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'citizen_last_contact_at')
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'responsible_subject_last_contact_at')

    ObjectManager::Attribute.migration_execute
  end
end
