class OpsChangeVisibilityDefaults < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    fields = ['responsible_subject', 'responsible_subject_changed_at', 'address_lat', 'address_lon', 'address_postcode']
    ObjectManager::Attribute.where(name: fields, object_lookup_id: ObjectLookup.by_name('Ticket')).update_all(
      screens: {
        create_middle: {
          'ticket.agent' => { shown: false }
        },
        edit: {
          'ticket.agent' => { shown: false }
        }
      }
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
