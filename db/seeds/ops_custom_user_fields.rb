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