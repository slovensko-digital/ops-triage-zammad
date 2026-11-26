# Recreates the search indexes that Zammad did not create itself, and queues a SearchIndexJob for each of their records.
#
# Zammad creates an index (mapping and settings, e.g. 2000 fields) only in zammad:searchindex:rebuild, and the image runs
# that only when there is no Ticket index. A model that becomes indexable in a Zammad upgrade (AuditLog in 7.x) gets its
# index from Elasticsearch, on its first document: a dynamic mapping, with the default limit of 1000 fields. Zammad maps
# AuditLog value_from/value_to as one flattened field each, the dynamic mapping adds a field per key of the audited
# object (every overview, trigger or workflow condition), until the limit is exceeded and SearchIndexJob fails.
#
# Zammad always sets index.max_result_window, Elasticsearch never does, so an index without it was not made by Zammad.
# Until the queued jobs finish, search in a recreated index finds fewer records.
class Ops::SearchIndexRepair
  ZAMMAD_SETTING = 'max_result_window'.freeze

  def initialize(out: $stdout)
    @out = out
  end

  # Returns the repaired models. Without a Ticket index it is a new setup, the image's full rebuild creates all indexes
  # and the attachment pipeline.
  def run
    return [] if !SearchIndexBackend.enabled?
    return [] if state(Ticket) == :missing

    Models.indexable.filter_map { |model| repair(model) }
  end

  def state(model)
    url = "#{SearchIndexBackend.build_url(type: model.name, with_pipeline: false, with_document_type: false)}/_settings"
    response = SearchIndexBackend.make_request(url)
    return :missing if response.code.to_s == '404'
    raise SearchIndexBackend.humanized_error(verb: 'GET', url:, response:) if !response.success?

    settings = response.data.values.first.dig('settings', 'index')
    settings.key?(ZAMMAD_SETTING) ? :ok : :not_by_zammad
  end

  private

  def repair(model)
    state = state(model)
    return if state == :ok

    @out.puts "#{model.name}: index #{state == :missing ? 'missing' : 'not created by Zammad'}, " \
              "recreating it and queueing #{model.count} records for indexing"
    recreate(model)
    model.in_batches.each_record { |record| SearchIndexJob.perform_later(model.name, record.id) }
    model
  end

  # A running worker indexing a record between the drop and the create makes Elasticsearch create the index again.
  def recreate(model, attempts: 3)
    SearchIndexBackend.drop_index([model])
    SearchIndexBackend.create_index([model])
  rescue RuntimeError => e
    raise if !e.message.include?('resource_already_exists_exception') || (attempts -= 1).zero?

    retry
  end
end
