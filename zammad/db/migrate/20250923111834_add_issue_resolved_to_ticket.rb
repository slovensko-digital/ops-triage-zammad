class AddIssueResolvedToTicket < ActiveRecord::Migration[7.1]
  def up
    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'issue_resolved',
      display: __('Aktualizácia zatvára podnet'),
      data_type: 'select',
      data_option: {
        options: {
          "yes" => "Áno",
          "no" => "Nie"
        },
        default: '',
        maxlength: 255,
        nulloption: true,
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
      position: 16,
      created_by_id: 1,
      updated_by_id: 1
    )
  end

  def down
    ObjectManager::Attribute.remove('Ticket', 'issue_resolved')
  end
end
