class RemapCategoriesJob < ApplicationJob
  CATEGORY_MAPPING = {
    [ "Zvieratá", "výbehy pre zvieratá", "túlavé mačky/psy" ] => [ "Zvieratá", "domáce zvieratá", "túlavé mačky/psy"],
    [ "Zvieratá", "výbehy pre zvieratá", "lesná zver" ] => [ "Zvieratá", "lesná zver", nil ],
    [ "Zvieratá", "výbehy pre zvieratá", "hmyz" ] => [ "Zvieratá", "hmyz", nil ],
    [ "Zvieratá", "domáce zvieratá", "výbehy pre zvieratá" ] => [ "Zvieratá", "výbehy pre zvieratá", "znečistené/poškodené/chýbajúce/iné" ],
    [ "Zvieratá", "zver v meste", "premnožené hlodavce" ] => [ "Zvieratá", "premnožené hlodavce", nil ]
  }

  def perform
    Ticket.transaction do
      CATEGORY_MAPPING.each do |old, new|
        Ticket.where(
          category: old[0],
          subcategory: old[1],
          subtype: old[2]
        ).update_all(
          category: new[0],
          subcategory: new[1],
          subtype: new[2]
        )
      end
    end
  end
end
