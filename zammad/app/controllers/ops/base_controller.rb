# The Ops admin pages (config/routes/ops.rb) for admins logged in to Triage, in the layout 'ops'. Each controller needs
# its policy in app/policies/controllers/ops/.
#
# In the admin's Zammad language, Slovak or English (config/locales/ops.*.yml); times as they render, in UTC, Zammad's
# Time.zone.
class Ops::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  around_action :with_user_locale

  layout 'ops'
  helper_method :describe_user

  LOCALES = %w[sk en].freeze

  private

  def with_user_locale(&)
    I18n.with_locale(user_locale, &)
  end

  # the admin's Zammad language (sk-sk), else the system's, else English
  def user_locale
    [current_user&.preferences&.dig('locale'), Setting.get('locale_default')]
      .map { |locale| locale.to_s[0, 2].presence_in(LOCALES) }.compact.first || 'en'
  end

  def describe_user(user)
    return '—' unless user

    "#{[user.firstname, user.lastname].compact_blank.join(' ')} <#{user.email}> (##{user.id})"
  end

  def redirect_to_login
    redirect_to '/#login'
  end
end
