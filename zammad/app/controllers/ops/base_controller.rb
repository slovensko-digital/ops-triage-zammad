# The Ops admin pages (config/routes/ops.rb) for admins logged in to Triage. Each controller needs its policy in
# app/policies/controllers/ops/.
class Ops::BaseController < ApplicationController
  prepend_before_action :authenticate_and_authorize!
  prepend_before_action :redirect_to_login, unless: -> { authentication_check_only }

  layout 'ops'
  helper Ops::UsersHelper

  private

  def redirect_to_login
    redirect_to '/#login'
  end
end
