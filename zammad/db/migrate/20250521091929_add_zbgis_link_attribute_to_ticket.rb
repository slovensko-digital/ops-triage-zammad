class AddZbgisLinkAttributeToTicket < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'zbgis_link',
      display: 'Odkaz na kataster',
      data_type: 'input',
      data_option: {
        default: 'Odkaz na kataster',
        type: 'text',
        maxlength: 120,
        linktemplate: "https://zbgis.skgeodesy.sk/mapka/sk/kataster/identification/point/\#{ticket.address_lat},\#{ticket.address_lon}?pos=\#{ticket.address_lat},\#{ticket.address_lon},18",
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
      position: 61,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute

    Ticket.update_all(zbgis_link: 'Odkaz na kataster')
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'zbgis_link')
    ObjectManager::Attribute.migration_execute
  end
end
