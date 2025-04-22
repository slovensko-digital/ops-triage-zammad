ObjectManager::Attribute.add(
  object: 'User',
  name: 'banned',
  display: 'Zakázaný prístup',
  data_type: 'boolean',
  data_option: {
    options: {
      false: 'nie',
      true: 'áno'
    },
    default: false,
    translate: false,
    null: true,
  },
  editable: true,
  active: true,
  screens: {
    edit: { 'admin.user' => { shown: true } },
    view: { 'admin.user' => { shown: true } },
  },
  position: 1900,
  created_by_id: 1,
  updated_by_id: 1
)

ObjectManager::Attribute.add(
  object: 'User',
  name: 'origin',
  display: __('Zdroj používateľa'),
  data_type: 'select',
  data_option: {
    options: [
      { name: 'Portál', value: 'portal' }
    ],
    customsort: 'on',
    default: nil,
    null: true,
    nulloption: true,
    maxlength: 100,
  },
  active: true,
  screens: {},
  position: 2000,
  created_by_id: 1,
  updated_by_id: 1
)