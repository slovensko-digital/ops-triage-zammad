class AddPortalDuplicatesUrl < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'portal_duplicates_url',
      display: 'Podobné podnety v okolí',
      data_type: 'input',
      data_option: {
        default: 'Okdaz na podobné podnety',
        type: 'text',
        maxlength: 120,
        linktemplate: File.join(
          ENV.fetch('OPS_PORTAL_PUBLIC_URL', ENV.fetch('OPS_PORTAL_URL', 'http://host.docker.internal:3000')),
          'dopyty?pin=#{ticket.address_lat}%2C#{ticket.address_lon}&tab=list'
        ),
        null: true,
        options: {},
        relation: ''
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
      position: 102,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute

    Ticket.update_all(portal_duplicates_url: 'Okdaz na podobné podnety')
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'portal_duplicates_url'
    )

    ObjectManager::Attribute.migration_execute
  end
end
