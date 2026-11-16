# The owner handover pages of Ops::OwnerHandoversController and Ops::OwnerHandoverRunsController: their layout with the
# tabs, and the helpers of their views. Each controller tells the tab its pages show under.
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

  # the runs of the step the preview form posts (step, new_owner_id, groups[], owners[]) for the owner leaving
  def build_runs(old_owner)
    form = params.slice(:step, :new_owner_id, :groups, :owners).permit(:step, :new_owner_id, groups: [], owners: {})
    Ops::OwnerHandoverRun.build_for(old_owner, form.to_h.symbolize_keys, created_by: current_user)
  end
end
