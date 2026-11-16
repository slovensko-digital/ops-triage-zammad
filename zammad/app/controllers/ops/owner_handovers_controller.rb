# The owner handover for admins, in tabs: an agent's report, the conflicts and the runs (Ops::OwnerHandoverRunsController).
# Dry runs right away and the steps applied by Ops::OwnerHandoverJob right away. The same classes as the
# ops:owner_handover rake tasks, with their default test customers.
#
# The agent's report leads the handover: 1. the triggers, a new owner picked for each group, 2. the tickets, moved to
# the agent each group is routed to then. Applying a step comes back to the report, which follows its runs.
class Ops::OwnerHandoversController < Ops::BaseController
  before_action :set_old_owner, only: %i[show preview]

  helper_method :busy_run, :routing_text

  # the form of the owner leaving asks with their email, as the agent field gives it
  def index
    email = params[:email].to_s.strip.downcase
    return if email.blank?

    user = User.find_by(email:)
    return redirect_to(ops_owner_handover_path(user)) if user

    flash.now[:alert] = ot('index.no_user', email:)
  end

  def conflicts
    @conflicts = Ops::OwnerConflicts.new(out: StringIO.new).conflicts
    @open_state_ids = Ticket::State.by_category(:open).pluck(:id)
  end

  def show
    out = StringIO.new
    handover = Ops::OwnerHandover.new(@old_owner.email, out:)
    @groups = handover.groups_overview.group_by(&:status)
    handover.report
    @report = out.string
    @runs = Ops::OwnerHandoverRun.where(old_owner_email: @old_owner.email).recent.limit(10).to_a
  rescue ArgumentError => e
    redirect_to ops_owner_handovers_path, alert: e.message
  end

  # the dry run of a step, with the form queueing it (Ops::OwnerHandoverRunsController#create)
  def preview
    @runs = build_runs(@old_owner)
    @error = ot('preview.no_owner') if @runs.empty?
    @error ||= @runs.flat_map { |run| run.errors.full_messages if run.invalid? }.compact.uniq.join("\n").presence
    return render(:preview, status: :unprocessable_content) if @error

    @outputs = @runs.map do |run|
      out = StringIO.new
      error = begin
        run.perform(out:)
        nil
      rescue ArgumentError => e
        e.message
      end
      [run, out.string, error]
    end
  end

  private

  def tab
    action_name == 'conflicts' ? :conflicts : :hand_over
  end

  # the owner leaving, by user id
  def set_old_owner
    @old_owner = User.find(params[:id])
  end

  # routes { owner id => trigger ids } of a group, when not a single other agent
  def routing_text(routes)
    return ot('routing.none') if routes.empty?

    described = routes.map do |owner_id, trigger_ids|
      user = User.find_by(id: owner_id)
      ot('routing.by', user: user ? describe_user(user) : ot('unknown_user', id: owner_id),
                       triggers: trigger_ids.map { |id| "##{id}" }.join(', '))
    end
    routes.size > 1 ? ot('routing.several', routes: described.join('; ')) : described.first
  end

  # the queued or running run of the report touching the group, if any
  def busy_run(label)
    @runs.find { |run| run.active? && (run.groups.blank? || run.groups.include?(label)) }
  end
end
