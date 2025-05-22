class AddUuidToTicketArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :ticket_articles, :uuid, :uuid
    add_index :ticket_articles, :uuid, unique: true
  end
end
