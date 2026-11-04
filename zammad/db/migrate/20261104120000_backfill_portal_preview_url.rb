class BackfillPortalPreviewUrl < ActiveRecord::Migration[7.2]
  # Must match IssuePreviewSigner in ops-portal.
  TOKEN_LENGTH = 20

  def up
    return unless column_exists?(:tickets, :portal_preview_url)

    secret = ENV['ISSUE_PREVIEW_SECRET'].presence
    portal_url = ENV['OPS_PORTAL_PUBLIC_URL'].presence || ENV['OPS_PORTAL_URL'].presence
    return unless secret && portal_url

    tickets = Ticket
      .where(process_type: %w[portal_issue_triage portal_issue_resolution])
      .where.not(ops_issue_identifier: [nil, ''])
      .where(portal_preview_url: [nil, ''])

    tickets.pluck(:id, :ops_issue_identifier).each do |id, issue_id|
      issue_id = issue_id.to_s.strip
      token = OpenSSL::HMAC.hexdigest('SHA256', secret, issue_id).first(TOKEN_LENGTH)
      url = "#{File.join(portal_url, 'dopyty', issue_id)}?nahlad=#{token}"

      Ticket.where(id: id).update_all(portal_preview_url: url)
    end
  end

  def down
  end
end
