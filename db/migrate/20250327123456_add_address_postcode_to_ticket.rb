class AddAddressPostcodeToTicket < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'address_postcode',
      display: 'Adresa (PSČ)',
      data_type: 'input',
      data_option: {
        default: '',
        type: 'text',
        maxlength: 8,
        linktemplate: "",
        null: true,
        options: {},
        relation: ''
      },
      active: true,
      screens: {
        edit: {
          'ticket.agent' => { shown: true }
        },
      },
      position: 58,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'address_postcode',
    )

    ObjectManager::Attribute.migration_execute
  end
end
