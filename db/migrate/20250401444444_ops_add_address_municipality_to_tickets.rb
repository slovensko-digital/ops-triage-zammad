class OpsAddAddressMunicipalityToTickets < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'address_municipality',
      display: __('Adresa (Oblasť)'),
      data_type: 'tree_select',
      data_option: {
        options: [],
        default: '',
        null: true,
        nulloption: true,
        maxlength: 255,
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
      position: 50,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.remove(object: 'Ticket', name: 'municipality') # drop old field

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'address_municipality',
    )

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'municipality',
      display: __('Oblasť'),
      data_type: 'tree_select',
      data_option: {
        options: [],
        default: '',
        null: true,
        nulloption: true,
        maxlength: 255,
      },
      active: true,
      screens: {
        create_middle: {
          'ticket.customer' => { shown: true },
          'ticket.agent' => { shown: true }
        },
        edit: {
          'ticket.customer' => { shown: true },
          'ticket.agent' => { shown: true }
        }
      },
      position: 21,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end
end
