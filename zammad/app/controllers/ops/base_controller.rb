# The Ops admin pages (config/routes/ops.rb) for admins logged in to Triage, in the layout 'ops'. Each controller needs
# its policy in app/policies/controllers/ops/.
#
# In English; times as they render, in UTC, Zammad's Time.zone.
class Ops::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  layout 'ops'
  helper_method :describe_user

  private

  def describe_user(user)
    return '—' unless user

    "#{[user.firstname, user.lastname].compact_blank.join(' ')} <#{user.email}> (##{user.id})"
  end

  def redirect_to_login
    redirect_to '/#login'
  end
end
