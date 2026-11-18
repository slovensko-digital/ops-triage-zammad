# Owner handover for admins, on top of the same classes as the ops:owner_handover rake tasks. The agent's report leads
# the handover: 1. triggers, a new owner per group, 2. tickets, moved to the agent each group is routed to then.
class Ops::OwnerHandoversController < Ops::BaseController
  include Ops::OwnerHandoverPages

  before_action :set_old_owner, only: %i[show preview]

  helper_method :busy_run

  def index
    redirect_to ops_owner_handover_path(params[:owner_id]) if params[:owner_id].present?
  end

  def mismatches
    @mismatches = Ops::OwnerMismatches.new(out: StringIO.new).mismatches
    @open_state_ids = Ticket::State.by_category(:open).pluck(:id)
  end

  def show
    out = StringIO.new
    handover = Ops::OwnerHandover.new(@old_owner.email, out:)
    @groups = handover.groups_overview.group_by(&:status)
    handover.report
    @report = out.string
    @runs = Ops::OwnerHandoverRun.where(old_owner: @old_owner).includes(:new_owner, :created_by).recent.limit(10).to_a
  rescue ArgumentError => e
    redirect_to ops_owner_handovers_path, alert: e.message
  end

  # @outputs are [run, output, error, tickets it moves], the tickets nil for the triggers step
  def preview
    @runs = build_runs(@old_owner)
    @error = 'Pick the new owner of at least one group.' if @runs.empty?
    @error ||= @runs.flat_map { |run| run.errors.full_messages if run.invalid? }.compact.uniq.join("\n").presence
    return render(:preview, status: :unprocessable_content) if @error

    @outputs = @runs.map do |run|
      out = StringIO.new
      moved, error = begin
        [run.perform(out:), nil]
      rescue ArgumentError => e
        [nil, e.message]
      end
      [run, out.string, error, run.step == 'triggers' ? nil : moved&.size]
    end
  end

  private

  def tab
    action_name == 'mismatches' ? :mismatches : :hand_over
  end

  def set_old_owner
    @old_owner = User.find(params[:id])
  end

  # the queued or running run of the report touching the group, if any
  def busy_run(label)
    @runs.find { |run| run.active? && (run.groups.blank? || run.groups.include?(label)) }
  end
end
