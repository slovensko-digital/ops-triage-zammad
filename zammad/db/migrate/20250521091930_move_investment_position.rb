class MoveInvestmentPosition < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.where(name: 'investment').update_all(position: 99)

    ObjectManager::Attribute.migration_execute
  end
  def down
    ObjectManager::Attribute.where(name: 'investment').update_all(position: 61)

    ObjectManager::Attribute.migration_execute
  end
end
