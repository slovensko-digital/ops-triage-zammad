# Groups the 700 routing triggers by shape, see Ops::RoutingTriggerShapes. Read only.
#
#   rake ops:routing_triggers:shapes
namespace :ops do
  namespace :routing_triggers do
    desc 'Group the 700 routing triggers by shape to find the ones that differ from the known shapes'
    task shapes: :environment do
      Ops::RoutingTriggerShapes.new.report
    end
  end
end
