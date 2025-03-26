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
