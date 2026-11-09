class FixTypoInNefunkcneSubtype < ActiveRecord::Migration[7.2]
  # The "osvetlenie" subtype was "nefunknčné" (ops#1346). The portal renames it too and the
  # two apps match subtypes by name. The select option itself is updated by ops:triage:migrate,
  # which runs after db:migrate and rebuilds the options from OPS_CATEGORIES_MAP.
  # Plain SQL on purpose: no history entries and no triggers/webhooks back to the portal.
  def up
    return unless column_exists?(:tickets, :subtype)

    execute "UPDATE tickets SET subtype = 'nefunkčné' WHERE subtype = 'nefunknčné'"
  end

  def down
    return unless column_exists?(:tickets, :subtype)

    execute "UPDATE tickets SET subtype = 'nefunknčné' WHERE subtype = 'nefunkčné' AND subcategory = 'osvetlenie'"
  end
end
