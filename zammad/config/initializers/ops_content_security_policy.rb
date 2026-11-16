# The admin menu shows the Ops admin pages (/ops/..., see public/assets/ops-admin-nav.js) in an iframe, Zammad's
# frame-src allows only the video embeds. Adds 'self' to them; loads after Zammad's content_security_policy.rb, the
# block form of config.content_security_policy would replace its policy.
policy = Rails.application.config.content_security_policy
policy.frame_src(:self, *policy.directives['frame-src']) unless policy.directives['frame-src']&.include?("'self'")
