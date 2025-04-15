class OpsAddTicketBodyTextarea < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'body',
      display: __('Finálny text podnetu'),
      data_type: 'textarea',
      data_option: {
        default: '',
        maxlength: 8192,
        rows: 10,
        null: true,
      },
      active: true,
      screens: {
        create_middle: {
          'ticket.customer' => { shown: false },
          'ticket.agent' => { shown: false }
        },
        edit: {
          'ticket.customer' => { shown: false },
          'ticket.agent' => { shown: false }
        }
      },
      position: 39,
      created_by_id: 1,
      updated_by_id: 1
    )

    ObjectManager::Attribute.migration_execute

    Ticket.where(origin: "portal").each do |ticket|
      first_article = ticket.articles.first
      ticket.body = first_article.body if first_article
      ticket.save
    end

    Ticket.where(body: nil).update_all(body: '')
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'body')

    ObjectManager::Attribute.migration_execute
  end
end
