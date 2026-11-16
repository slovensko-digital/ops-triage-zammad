# The steps of owner handovers queued from Ops::OwnerHandoversController#preview and run by Ops::OwnerHandoverJob: the
# Jobs tab, a run's log, and the statuses public/assets/ops-run-watch.js polls.
class Ops::OwnerHandoverRunsController < Ops::BaseController
  def index
    @runs = Ops::OwnerHandoverRun.recent.includes(:created_by).limit(30)
  end

  def show
    @run = Ops::OwnerHandoverRun.find(params[:id])
  end

  # the step as its preview showed it, for the owner leaving in old_owner_id
  def create
    old_owner = User.find(params[:old_owner_id])
    runs = build_runs(old_owner)
    if runs.empty? || runs.any?(&:invalid?)
      return redirect_to(ops_owner_handover_path(old_owner), alert: ot('create_run.nothing'))
    end

    Ops::OwnerHandoverRun.transaction { runs.each(&:save!) }
    runs.each { |run| Ops::OwnerHandoverJob.perform_later(run.id) }
    redirect_to ops_owner_handover_path(old_owner),
                notice: ot('create_run.queued', runs: runs.map { |run| "##{run.id}" }.join(', '))
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
