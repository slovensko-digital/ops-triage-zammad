class RemoveOldClosedTicketNotificationTrigger < ActiveRecord::Migration[7.1]
  def up
    Trigger.find_by(name: '100 - ops - upozornenie na komentovanie uzavretých zamietnutých triážnych tiketov')&.destroy
  end

  def down
    # This migration is not reversible as it removes a trigger.
    # If you need to restore it, you would have to recreate the trigger manually.
  end
end
