class AddPublicAttributeToTicket < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'portal_public',
      display: __('Zverejniteľné na portáli'),
      data_type: 'boolean',
      data_option: {
        options: { false => 'nie', true => 'áno' },
        default: true
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
      position: 16,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'Ticket',
      name: 'portal_public'
    )
  end
end
