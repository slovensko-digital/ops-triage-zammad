# Runs an Ops::OwnerHandoverRun queued from /ops/owner_handover, with dry_run: false. One runner at a time
# (Ops::OwnerHandoverRun.with_runner_lock): while another one runs, it waits and tries again. Never retried, a failed
# run is queued again from the page.
class Ops::OwnerHandoverJob < ApplicationJob
  BUSY_RETRY_IN = 5.minutes

  def self.max_run_time
    12.hours
  end

  def perform(run_id)
    run = Ops::OwnerHandoverRun.find_by(id: run_id)
    return unless run&.status == 'queued'

    locked = Ops::OwnerHandoverRun.with_runner_lock do
      Ops::OwnerHandoverRun.fail_abandoned!
      execute(run) if run.start!
    end
    self.class.set(wait: BUSY_RETRY_IN).perform_later(run.id) unless locked
  end

  private

  def execute(run)
    out = run.log_writer
    run.perform(out:, dry_run: false)
    run.finish!
  rescue => e
    out&.puts("!! #{e.class}: #{e.message}")
    run.finish!(error: "#{e.class}: #{e.message}\n#{e.backtrace&.first(15)&.join("\n")}")
  end
end
