class AddPreviousResponsibleSubjectToTicket < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute.add(
      object: 'Ticket',
      name: 'previous_responsible_subject',
      display: __('Predchádzajúci zodpovedný subjekt'),
      data_type: 'autocompletion_ajax_external_data_source',
      data_option: {
        search_url: "#{ENV['OPS_PORTAL_URL']}/api/v1/responsible_subjects/search?q=\#{search.term}",
        verify_ssl: ENV['OPS_PORTAL_URL'].start_with?('https'),
        http_auth_type: "",
        search_result_list_key: "",
        search_result_value_key: "id",
        search_result_label_key: "name",
        options: {},
        default: {},
        null: true,
        nulloption: true,
      },
      active: true,
      screens: {
        create_middle: {
          'ticket.agent' => { shown: false }
        },
        edit: {
          'ticket.agent' => { shown: false }
        }
      },
      position: 23,
      created_by_id: 1,
      updated_by_id: 1
    )
  end

  def down
    ObjectManager::Attribute.remove(object: 'Ticket', name: 'previous_responsible_subject')
  end
end
