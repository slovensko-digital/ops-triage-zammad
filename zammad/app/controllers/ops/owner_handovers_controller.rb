# The owner handover for admins, in tabs: an agent's report, the conflicts and the runs. Dry runs right away and the
# steps applied by Ops::OwnerHandoverJob right away. The same classes as the ops:owner_handover rake tasks, with their
# default test customers.
class Ops::OwnerHandoversController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  layout 'ops'
  helper_method :describe_user, :time_in_zone, :tab

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
    @groups = handover.groups_overview
    handover.report
    @report = out.string
  rescue ArgumentError => e
    redirect_to ops_owner_handover_path, alert: e.message
  end

  # the dry run of a step, with the form queueing it
  def preview
    @run = build_run
    return render(:preview, status: :unprocessable_content) if @run.invalid?

    out = StringIO.new
    begin
      dry_run(@run, out)
    rescue ArgumentError => e
      @error = e.message
    end
    @output = out.string
  end

  def create_run
    run = build_run
    run.save!
    Ops::OwnerHandoverJob.perform_later(run.id)
    redirect_to ops_owner_handover_run_path(run)
  end

  def show_run
    @run = Ops::OwnerHandoverRun.find(params[:id])
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

  def build_run
    Ops::OwnerHandoverRun.new(
      step: params[:step],
      old_owner_email: params[:old_email].to_s.strip,
      new_owner_email: params[:new_email].to_s.strip.presence,
      groups: Array(params[:groups]).compact_blank.presence,
      created_by_id: current_user.id
    )
  end

  def dry_run(run, out)
    handover = Ops::OwnerHandover.new(run.old_owner_email, out:)
    case run.step
    when 'triggers' then handover.reassign_triggers!(to: run.new_owner_email, groups: run.groups)
    when 'tickets' then handover.reassign_tickets!(to: run.new_owner_email, groups: run.groups)
    end
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
