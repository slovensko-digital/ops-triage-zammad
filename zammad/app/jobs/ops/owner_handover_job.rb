# Runs an Ops::OwnerHandoverRun queued from /ops/owner_handover, with dry_run: false. One run at a time: while another
# is running, it waits and tries again. Never retried, a failed run is queued again from the page.
class Ops::OwnerHandoverJob < ApplicationJob
  BUSY_RETRY_IN = 5.minutes

  def self.max_run_time
    12.hours
  end

  def perform(run_id)
    run = Ops::OwnerHandoverRun.find_by(id: run_id)
    return unless run&.status == 'queued'

    busy = Ops::OwnerHandoverRun.where(status: 'running').where.not(id: run.id).first
    if busy
      self.class.set(wait: BUSY_RETRY_IN).perform_later(run.id)
      return
    end
    return unless run.start!

    execute(run)
  end

  private

  def execute(run)
    out = run.log_writer
    handover = Ops::OwnerHandover.new(run.old_owner_email, out:)
    groups = run.groups.presence

    case run.step
    when 'triggers' then handover.reassign_triggers!(to: run.new_owner_email, groups:, dry_run: false)
    when 'tickets' then handover.reassign_tickets!(to: run.new_owner_email, groups:, dry_run: false)
    when 'reindex' then handover.reindex_tickets!(groups:)
    end
    run.finish!
  rescue => e
    out&.puts("!! #{e.class}: #{e.message}")
    run.finish!(error: "#{e.class}: #{e.message}\n#{e.backtrace&.first(15)&.join("\n")}")
  end
end
