module Ops::UserExtensions
  def check_login
    if login.present?
      self.login = login.downcase.strip
      exists = User.find_by(login: login)
      return true if !exists || exists.id == id

      raise Exceptions::UnprocessableEntity, "Invalid user login generation for login #{login}!"
    end

    super
  end
end
