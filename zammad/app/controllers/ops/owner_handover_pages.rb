# Shared by the owner handover controllers: the layout with tabs, the helpers and the runs of the preview form. Each
# controller defines its tab.
module Ops::OwnerHandoverPages
  extend ActiveSupport::Concern

  included do
    layout 'ops_owner_handover'
    helper Ops::OwnerHandoversHelper
    helper_method :tab
  end

  private

  def tab
    raise NotImplementedError
  end

  def build_runs(old_owner)
    form = params.slice(:step, :new_owner_id, :groups, :owners).permit(:step, :new_owner_id, groups: [], owners: {})
    Ops::OwnerHandoverRun.build_for(old_owner, form.to_h.symbolize_keys, created_by: current_user)
  end
end
