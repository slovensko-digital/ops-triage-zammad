# The steps of owner handovers queued from Ops::OwnerHandoversController#preview and run by Ops::OwnerHandoverJob: the
# Jobs tab, a run's log, and the statuses public/assets/ops-run-watch.js polls.
class Ops::OwnerHandoverRunsController < Ops::BaseController
  include Ops::OwnerHandoverPages

  def index
    @runs = Ops::OwnerHandoverRun.recent.includes(:old_owner, :new_owner, :created_by).limit(30)
  end

  def show
    @run = Ops::OwnerHandoverRun.find(params[:id])
  end

  # the step as its preview showed it, for the owner leaving in old_owner_id
  def create
    old_owner = User.find(params[:old_owner_id])
    runs = build_runs(old_owner)
    if runs.empty? || runs.any?(&:invalid?)
      return redirect_to(ops_owner_handover_path(old_owner), alert: 'Nothing to apply, preview the step again.')
    end

    Ops::OwnerHandoverRun.transaction { runs.each(&:save!) }
    runs.each { |run| Ops::OwnerHandoverJob.perform_later(run.id) }
    redirect_to ops_owner_handover_path(old_owner),
                notice: "Queued #{runs.map { |run| "##{run.id}" }.join(', ')}. It runs in the background, " \
                        'this page follows it and updates when it ends.'
  end

  # { id => status } of the runs asked for
  def statuses
    ids = Array(params[:ids]).map(&:to_i)
    render json: Ops::OwnerHandoverRun.where(id: ids).pluck(:id, :status).to_h
  end

  private

  def tab
    :runs
  end
end
