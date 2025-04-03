class OpsRemoveOldAddressFieldsFromTickets < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    %w[
      address_city
      address_city_district
      address_suburb
      address_village
      address_road
    ].each do |field|
      ObjectManager::Attribute.remove(object: 'Ticket', name: field)
    end

    ObjectManager::Attribute.migration_execute
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
