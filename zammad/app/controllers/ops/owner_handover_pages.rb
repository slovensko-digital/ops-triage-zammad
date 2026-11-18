# Layout with tabs and view helpers of the owner handover controllers. Each controller defines its tab.
module Ops::OwnerHandoverPages
  extend ActiveSupport::Concern

  included do
    layout 'ops_owner_handover'
    helper_method :tab, :step_name
  end

  private

  def tab
    raise NotImplementedError
  end

  STEP_NAMES = { 'tickets_routed' => 'tickets to the owners by trigger' }.freeze

  def step_name(step)
    STEP_NAMES.fetch(step.to_s, step.to_s)
  end

  def build_runs(old_owner)
    form = params.slice(:step, :new_owner_id, :groups, :owners).permit(:step, :new_owner_id, groups: [], owners: {})
    Ops::OwnerHandoverRun.build_for(old_owner, form.to_h.symbolize_keys, created_by: current_user)
  end
end
