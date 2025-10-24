ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'portal_public',
  display: __('Zverejniteľné na portáli'),
  data_type: 'boolean',
  data_option: {
    options: { false => 'nie', true => 'áno' },
    default: true,
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
  position: 22,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'responsible_subject_changed_at',
  display: 'Posledná zmena zodpovedného subjektu',
  data_type: 'datetime',
  data_option: {
    future: true,
    past: true,
    diff: nil,
    default: nil,
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    create_middle: {
      'ticket.agent' => { shown: false }
    },
    edit: {
      'ticket.agent' => { shown: false }
    },
  },
  position: 23,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'address_municipality',
  display: __('Adresa (Oblasť)'),
  data_type: 'tree_select',
  data_option: {
    options: [],
    default: '',
    null: true,
    nulloption: true,
    maxlength: 255,
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
  position: 50,
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
      'ticket.agent' => { shown: false }
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
    linktemplate: "https://www.google.com/maps/search/?api=1&query=\#{ticket.address_lat},\#{ticket.address_lon}",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: false }
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
    linktemplate: "https://www.google.com/maps/search/?api=1&query=\#{ticket.address_lat},\#{ticket.address_lon}",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: false }
    },
  },
  position: 60,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'investment',
  display: __('Investičná akcia'),
  data_type: 'boolean',
  data_option: {
    options: { false => 'nie', true => 'áno' },
    default: false,
    null: true,
    relation: ''
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
  position: 99,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'portal_url',
  display: 'Odkaz na portál',
  data_type: 'input',
  data_option: {
    default: '',
    type: 'url',
    maxlength: 2048,
    null: true,
    options: {},
    relation: ''
  },
  editable: true,
  active: true,
  screens: {
    edit: {
      'ticket.agent' => { shown: false },
      'ticket.customer' => { shown: false }
    },
    create_middle: {
      'ticket.customer' => { shown: false },
      'ticket.agent' => { shown: false }
    }
  },
  position: 101,
  created_by_id: 1,
  updated_by_id: 1
)

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

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'zbgis_link',
  display: 'Odkaz na kataster',
  data_type: 'input',
  data_option: {
    default: 'Odkaz na kataster',
    type: 'text',
    maxlength: 120,
    linktemplate: "https://zbgis.skgeodesy.sk/mapka/sk/kataster/identification/point/\#{ticket.address_lat},\#{ticket.address_lon}?pos=\#{ticket.address_lat},\#{ticket.address_lon},18",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    create_middle: {
      'ticket.agent' => { shown: false }
    },
    edit: {
      'ticket.agent' => { shown: false }
    },
  },
  position: 61,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'Ticket',
  name: 'ops_issue_identifier',
  display: 'ID dopytu na portáli',
  data_type: 'input',
  data_option: {
    default: '',
    type: 'text',
    maxlength: 10,
    linktemplate: "",
    null: true,
    options: {},
    relation: ''
  },
  active: true,
  screens: {
    create_middle: {
      'ticket.agent' => { shown: false }
    },
    edit: {
      'ticket.agent' => { shown: false }
    },
  },
  position: 103,
  created_by_id: 1,
  updated_by_id: 1
)
