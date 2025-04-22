class AddBannedToUser < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'User',
      name: 'banned',
      display: 'Zakázaný prístup',
      data_type: 'boolean',
      data_option: {
        options: {
          false: 'nie',
          true: 'áno'
        },
        default: false,
        translate: false,
        null: true,
      },
      editable: true,
      active: true,
      screens: {
        edit: { 'admin.user' => { shown: true } },
        view: { 'admin.user' => { shown: true } },
      },
      position: 1900,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute
  end

  def down
    ObjectManager::Attribute.remove(
      object: 'User',
      name: 'banned',
    )

    ObjectManager::Attribute.migration_execute
  end
end
