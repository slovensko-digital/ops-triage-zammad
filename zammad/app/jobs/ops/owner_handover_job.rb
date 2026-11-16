# Runs an Ops::OwnerHandoverRun queued from /ops/owner_handover, with dry_run: false. One runner at a time
# (Ops::OwnerHandoverRun.with_runner_lock): while another one runs, it waits and tries again. Never retried, a failed
# run is queued again from the page.
#
# Stopped after 4 hours, ApplicationJob.max_run_time: the background worker's Delayed::Worker.reset caps every job at
# that, a longer max_run_time here would not apply. The run fails, the group being moved then is rolled back and the
# groups moved before stay; queued again, the step goes on with the tickets left.
class Ops::OwnerHandoverJob < ApplicationJob
  BUSY_RETRY_IN = 5.minutes

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
