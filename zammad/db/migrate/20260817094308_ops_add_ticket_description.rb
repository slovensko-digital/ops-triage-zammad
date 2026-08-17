class OpsAddTicketDescription < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')
    return if ObjectManager::Attribute.exists?(object_lookup_id: 1, name: 'description')

    ObjectManager::Attribute.find_by(object_lookup_id: 1, name: "body")&.update(display: __('Finálny text podnetu old'))

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'description',
      display: __('Finálny text podnetu'),
      data_type: 'textarea',
      data_option: {
        default: '',
        maxlength: 8192,
        rows: 10,
        null: true,
      },
      active: true,
      screens: {
        create_middle: {
          'ticket.customer' => { shown: false },
          'ticket.agent' => { shown: false }
        },
        edit: {
          'ticket.customer' => { shown: false },
          'ticket.agent' => { shown: false }
        }
      },
      position: 39,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute

    # Copy the body to description for existing tickets fast using SQL
    Ticket.where(origin: "portal").update_all("description = body")
    Ticket.where(description: nil).update_all(description: '')
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'description')

    ObjectManager::Attribute.migration_execute
  end
end
