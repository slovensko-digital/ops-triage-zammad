class Ops::IdentifyResponsibleSubjectSender
  def self.run(_channel, mail, _transaction_params)
    return if mail[:'x-xammad-customer_id'].present?
    return if mail[:'x-zammad-ticket-number'].present?
    return if mail[:'x-zammad-ticket-id'].present?

    subject = mail[:subject]

    match = subject.match(%r{#R?-?(\d{5,6})})
    return unless match

    ticket = Ticket.find_by(number: "R-#{match[1]}")
    ticket = Ticket.find_by(ops_issue_identifier: match[1]) unless ticket
    return unless ticket
    return unless ticket.responsible_subject

    label = ticket.responsible_subject["label"]
    value = ticket.responsible_subject["value"]

    return if label.blank?

    org = Organization.find_by(name: label, active: true)
    return unless org

    member = org.members.where(active: true, email: mail[:from_email]).first
    return unless member

    responsible_subject_user = User.find_by(login: "ops-rs-#{value}", active: true)
    return unless responsible_subject_user

    mail[:'x-zammad-ticket-number'] = ticket.number
    mail[:'x-zammad-ticket-customer_id'] = responsible_subject_user.id
    mail[:'x-zammad-session-user-id'] = responsible_subject_user.id

    true
  end
end
