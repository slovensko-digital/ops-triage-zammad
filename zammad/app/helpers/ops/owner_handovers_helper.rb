module Ops::OwnerHandoversHelper
  STEP_NAMES = { 'tickets_routed' => 'tickets to the owners by trigger' }.freeze

  def step_name(step)
    STEP_NAMES.fetch(step.to_s, step.to_s)
  end

  # routes: { owner id => trigger ids }
  def routing_text(routes)
    return 'no active trigger routes this group' if routes.empty?

    described = routes.map do |owner_id, trigger_ids|
      user = User.find_by(id: owner_id)
      "#{user ? describe_user(user) : "unknown user ##{owner_id}"} by #{trigger_ids.map { |id| "##{id}" }.join(', ')}"
    end
    routes.size > 1 ? "several triggers route it: #{described.join('; ')}" : described.first
  end
end
