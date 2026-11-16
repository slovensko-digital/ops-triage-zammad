module Ops::TicketExtensions
  # Read by ignore_search_indexing? in the after_commit callback, so the block has to wrap the whole transaction.
  thread_mattr_accessor :search_index_update_skipped, instance_accessor: false

  # Updates no search index in the block: Zammad queues a SearchIndexJob and a SearchIndexAssociationsJob for every
  # changed ticket, which would flood the queue on a bulk update. The caller reindexes the tickets itself afterwards
  # with Ticket#search_index_update_backend.
  def self.without_search_index_update
    skipped = search_index_update_skipped
    self.search_index_update_skipped = true
    yield
  ensure
    self.search_index_update_skipped = skipped
  end

  def ignore_search_indexing?(action)
    return true if action == :update && Ops::TicketExtensions.search_index_update_skipped

    super
  end
end
