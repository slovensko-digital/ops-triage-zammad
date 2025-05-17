module Ops::UserExtensions
  def check_login
    # If login is specified (on user creation) do not try to generate a new one if not unique
    #
    # When creating users from OPS portal, we need to ensure that a user is not created multiple times, thus we provide unique value in login attribute.
    # By default, Zammad generates a new login if the provided one is not unique
    #
    if login.present?
      self.login = login.downcase.strip
      exists = User.find_by(login: login)
      return true if !exists || exists.id == id

      raise Exceptions::UnprocessableEntity, "Invalid user login generation for login #{login}!"
    end

    super
  end
end
