# The owner handover for admins, in tabs: an agent's report, the conflicts and the runs. Dry runs right away and the
# steps applied by Ops::OwnerHandoverJob right away. The same classes as the ops:owner_handover rake tasks, with their
# default test customers.
#
# The agent's report leads the handover: 1. the triggers, a new owner picked for each group, 2. the tickets, moved to
# the agent each group is routed to then. Applying a step comes back to the report, which follows its runs.
class Ops::OwnerHandoversController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  layout 'ops'
  helper_method :describe_user, :time_in_zone, :tab, :busy_run

  def index; end

  def conflicts
    @conflicts = Ops::OwnerConflicts.new(out: StringIO.new).conflicts
    @open_state_ids = Ticket::State.by_category(:open).pluck(:id)
  end

  def runs
    @runs = Ops::OwnerHandoverRun.recent.includes(:created_by).limit(30)
  end

  def report
    @email = params[:email].to_s.strip
    out = StringIO.new
    handover = Ops::OwnerHandover.new(@email, out:)
    @old_owner = handover.old_owner
    @groups = handover.groups_overview.group_by(&:status)
    handover.report
    @report = out.string
    @runs = Ops::OwnerHandoverRun.where(old_owner_email: @old_owner.email).recent.limit(10).to_a
  rescue ArgumentError => e
    redirect_to ops_owner_handover_path, alert: e.message
  end

  # the dry run of a step, with the form queueing it; the triggers step is a run for each new owner
  def preview
    @runs = build_runs
    @error = 'Pick the new owner of at least one group.' if @runs.empty?
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

  def create_run
    runs = build_runs
    if runs.empty? || runs.any?(&:invalid?)
      return redirect_to(ops_owner_handover_report_path(email: params[:old_email]), alert: 'Nothing to apply, preview the step again.')
    end

    Ops::OwnerHandoverRun.transaction { runs.each(&:save!) }
    runs.each { |run| Ops::OwnerHandoverJob.perform_later(run.id) }
    redirect_to ops_owner_handover_report_path(email: runs.first.old_owner_email),
                notice: "Queued #{runs.map { |run| "run ##{run.id}" }.join(', ')}. It runs in the background, " \
                        'this page follows it and updates when it ends.'
  end

  def show_run
    @run = Ops::OwnerHandoverRun.find(params[:id])
  end

  # { id => status } of the runs asked for, polled by public/assets/ops-run-watch.js
  def run_statuses
    ids = Array(params[:ids]).map(&:to_i)
    render json: Ops::OwnerHandoverRun.where(id: ids).pluck(:id, :status).to_h
  end

  private

  # the tab of the layout the page shows under
  def tab
    case action_name
    when 'conflicts' then 'Conflicts'
    when 'runs', 'show_run' then 'Runs'
    else 'Hand over an agent'
    end
  end

  def redirect_to_login
    redirect_to '/#login'
  end

  def build_runs
    attributes = { step: params[:step], old_owner_email: params[:old_email].to_s.strip.downcase,
                   created_by_id: current_user.id }
    return trigger_runs(attributes) if params[:step] == 'triggers'

    [Ops::OwnerHandoverRun.new(**attributes, new_owner_email: params[:new_email].to_s.strip.downcase.presence,
                                             groups: Array(params[:groups]).compact_blank.presence)]
  end

  # owners[group label] = new owner's email, the groups left empty stay as they are
  def trigger_runs(attributes)
    owners = params.fetch(:owners, {}).to_unsafe_h.transform_values { |email| email.to_s.strip.downcase }.compact_blank
    owners.group_by { |_label, email| email }.map do |email, pairs|
      Ops::OwnerHandoverRun.new(**attributes, new_owner_email: email, groups: pairs.map(&:first).sort)
    end
  end

  # the queued or running run of the report touching the group, if any
  def busy_run(label)
    @runs.find { |run| run.active? && (run.groups.blank? || run.groups.include?(label)) }
  end

  # the agents' time, not Zammad's timezone_default (UTC in a fresh install)
  ZONE = ActiveSupport::TimeZone['Europe/Bratislava']

  def time_in_zone(time)
    time&.in_time_zone(ZONE)&.strftime('%Y-%m-%d %H:%M:%S')
  end

  def describe_user(user)
    return '—' unless user

    "#{[user.firstname, user.lastname].compact_blank.join(' ')} <#{user.email}> (##{user.id})"
  end
end
