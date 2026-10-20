class RenameCategoriesJob < ApplicationJob
  def perform
    Ticket.transaction do
      Ticket.where(category: "Komunikácie", subcategory: "schody", subtype: "poškodená").update_all(subtype: "poškodené")
      Ticket.where(category: "Komunikácie", subcategory: "schody", subtype: "neodhrnutá").update_all(subtype: "neodhrnuté")
      Ticket.where(category: "Komunikácie", subcategory: "schody", subtype: "neposypaná").update_all(subtype: "neposypané")
      Ticket.where(category: "Komunikácie", subcategory: "schody", subtype: "znečistená").update_all(subtype: "znečistené")
      Ticket.where(category: "Kanalizácia", subcategory: "kanalizáčná vpusť").update_all(subcategory: "kanalizačná vpusť")
      Ticket.where(category: "Kanalizácia", subcategory: "kanalizáčná mriežka").update_all(subcategory: "kanalizačná mriežka")
      Ticket.where(category: "Osvetlenie", subcategory: "osvetlenie", subtype: "nefunknčné").update_all(subtype: "nefunkčné")
    end
  end
end
