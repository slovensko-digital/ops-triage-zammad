ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'responsible_subject',
  display: __('Zodpovedný subjekt'),
  data_type: 'autocompletion_ajax_external_data_source',
  data_option: {
    search_url: "#{ENV['OPS_PORTAL_URL']}/api/v1/responsible_subjects/search?q=\#{search.term}",
    verify_ssl: ENV['OPS_PORTAL_URL'].start_with?('https'),
    http_auth_type: "",
    search_result_list_key: "",
    search_result_value_key: "id",
    search_result_label_key: "name",
    options: {},
    default: '',
    null: true,
    nulloption: true,
  },
  active: true,
  screens: {
    create_middle: {
      'ticket.agent' => { shown: true }
    },
    edit: {
      'ticket.agent' => { shown: true }
    }
  },
  position: 22,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'address_postcode',
  display: 'Adresa (PSČ)',
  data_type: 'input',
  data_option: {
    default: '',
    type: 'text',
    maxlength: 8,
    linktemplate: "",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: true }
    },
  },
  position: 58,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'address_lat',
  display: 'Adresa (Zem. šírka)',
  data_type: 'input',
  data_option: {
    default: '',
    type: 'text',
    maxlength: 20,
    linktemplate: "https://www.openstreetmap.org/?mlat=\#{ticket.address_lat}&mlon=\#{ticket.address_lon}#map=18/\#{ticket.address_lat}/\#{ticket.address_lon}",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: true }
    },
  },
  position: 59,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'address_lon',
  display: 'Adresa (Zem. dĺžka)',
  data_type: 'input',
  data_option: {
    default: '',
    type: 'text',
    maxlength: 20,
    linktemplate: "https://www.openstreetmap.org/?mlat=\#{ticket.address_lat}&mlon=\#{ticket.address_lon}#map=18/\#{ticket.address_lat}/\#{ticket.address_lon}",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: true }
    },
  },
  position: 60,
  created_by_id: 1,
  updated_by_id: 1
)