class RemapTicketCategoryJob < ApplicationJob
  def perform(ticket)
    category, subcategory, subtype = Ops::CategoryMapper.map_legacy_categories_to_new(ticket.category, ticket.subcategory, ticket.subtype)

    ticket.update(
      category: category,
      subcategory: subcategory,
      subtype: subtype
    )
  end
end
