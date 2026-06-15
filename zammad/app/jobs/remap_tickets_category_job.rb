class RemapTicketsCategoryJob < ApplicationJob
  def perform
    Ticket.where(category: 1..7).find_each do |ticket|
      RemapTicketCategoryJob.perform_later(ticket)
    end
  end
end
