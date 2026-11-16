class SetTimezoneDefaultToBratislava < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Setting.set('timezone_default', 'Europe/Bratislava')
  end

  def down
    Setting.set('timezone_default', 'UTC')
  end
end
