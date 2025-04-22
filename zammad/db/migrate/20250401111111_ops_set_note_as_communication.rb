class OpsSetNoteAsCommunication < ActiveRecord::Migration[6.0]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Ticket::Article::Type.find_by_name(:note).update!(communication: true)
  end

  def down
    Ticket::Article::Type.find_by_name(:note).update!(communication: false)
  end
end
