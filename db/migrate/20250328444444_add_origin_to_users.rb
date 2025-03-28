class AddOriginToUsers < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'origin',
      display: __('Zdroj používateľa'),
      data_type: 'select',
      data_option: {
        options: [
          { name: 'Portál', value: 'portal' }
        ],
        customsort: 'on',
        default: nil,
        null: true,
        nulloption: true,
        maxlength: 100,
      },
      active: true,
      screens: {},
      position: 2000,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'User',
      name: 'origin',
    )

    ObjectManager::Attribute.migration_execute
  end
end
