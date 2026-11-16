# The Ops admin pages (config/routes/ops.rb) for admins logged in to Triage, in the layout 'ops'. Each controller needs
# its policy in app/policies/controllers/ops/ and a tab, the one of the layout its pages show under.
#
# In Slovak or English (config/locales/ops.*.yml), as the admin's Zammad language, switched by ?locale=sk|en for the
# session. The logs of the owner handover steps stay in English, the same as the rake tasks.
class Ops::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  around_action :switch_locale

  layout 'ops'
  helper_method :describe_user, :time_in_zone, :tab, :ot, :step_name, :status_name, :handover_path_for

  LOCALES = %w[sk en].freeze

  private

  def tab
    raise NotImplementedError
  end

  def switch_locale(&)
    session[:ops_locale] = params[:locale] if LOCALES.include?(params[:locale])
    I18n.with_locale(ops_locale, &)
  end

  # the one picked for the session, else the admin's Zammad language (sk-sk), else the system's, else English
  def ops_locale
    [session[:ops_locale], current_user&.preferences&.dig('locale'), Setting.get('locale_default')]
      .map { |locale| locale.to_s[0, 2].presence_in(LOCALES) }.compact.first || 'en'
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

  # the handover page of the owner with the email, nil when no user has it (runs keep the emails)
  def handover_path_for(email)
    @users_by_email ||= {}
    user = @users_by_email.fetch(email) { @users_by_email[email] = User.find_by(email:) }
    user && ops_owner_handover_path(user)
  end

  # the runs of a step of the old owner's handover as the preview form posts it (step, new_email, groups[], owners[]);
  # the triggers step is a run for each new owner
  def build_runs(old_owner)
    attributes = { step: params[:step], old_owner_email: old_owner.email, created_by_id: current_user.id }
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

  # the agents' time, not Zammad's timezone_default (UTC in a fresh install)
  ZONE = ActiveSupport::TimeZone['Europe/Bratislava']

  def time_in_zone(time)
    time&.in_time_zone(ZONE)&.strftime('%Y-%m-%d %H:%M:%S')
  end

  def describe_user(user)
    return '—' unless user

    "#{[user.firstname, user.lastname].compact_blank.join(' ')} <#{user.email}> (##{user.id})"
  end

  def redirect_to_login
    redirect_to '/#login'
  end
end
