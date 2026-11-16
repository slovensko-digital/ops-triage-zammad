# The owner handover pages of Ops::OwnerHandoversController and Ops::OwnerHandoverRunsController: their layout with the
# tabs, and the helpers of their views. Each controller tells the tab its pages show under.
module Ops::OwnerHandoverPages
  extend ActiveSupport::Concern

  included do
    layout 'ops_owner_handover'
    helper_method :tab, :ot, :step_name, :status_name
  end

  private

  def tab
    raise NotImplementedError
  end

  def ot(key, **)
    t("ops.owner_handover.#{key}", **)
  end

  def step_name(step)
    ot("steps.#{step}", default: step.to_s)
  end

  def status_name(status)
    ot("statuses.#{status}", default: status.to_s)
  end

  # the runs of the step the preview form posts (step, new_owner_id, groups[], owners[]) for the owner leaving
  def build_runs(old_owner)
    form = params.slice(:step, :new_owner_id, :groups, :owners).permit(:step, :new_owner_id, groups: [], owners: {})
    Ops::OwnerHandoverRun.build_for(old_owner, form.to_h.symbolize_keys, created_by: current_user)
  end
end
