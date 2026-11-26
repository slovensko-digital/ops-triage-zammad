# See Ops::SearchIndexRepair.
namespace :ops do
  namespace :search_index do
    # rake ops:search_index:repair
    # also runs in zammad-init on every boot, through ops:triage:migrate
    desc 'Recreate the search indexes Zammad did not create (new indexable models after an upgrade) and reindex them'
    task repair: :environment do
      Ops::SearchIndexRepair.new.run
    end
  end
end
