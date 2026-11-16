# One step of an owner handover queued from the admin page /ops/owner_handovers, run right away by
# Ops::OwnerHandoverJob with dry_run: false. The step's output goes to log line by line, so the page shows its progress.
#
#   triggers        Ops::OwnerHandover#reassign_triggers!
#   tickets         Ops::OwnerHandover#reassign_tickets!
#   tickets_routed  Ops::OwnerHandover#reassign_tickets_to_routed_owners!, no new owner
class Ops::OwnerHandoverRun < ActiveRecord::Base
  self.table_name = 'ops_owner_handover_runs'

  STEPS = %w[triggers tickets tickets_routed].freeze
  ACTIVE = %w[queued running].freeze

  belongs_to :old_owner, class_name: 'User'
  belongs_to :new_owner, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User'

  validates :step, inclusion: { in: STEPS }
  validates :old_owner, :created_by, presence: true
  validates :new_owner, presence: true, unless: :routed?

  scope :active, -> { where(status: ACTIVE) }
  scope :recent, -> { order(id: :desc) }

  # the Postgres advisory lock held by the one runner, see with_runner_lock
  RUNNER_LOCK_KEY = 7_316_001

  # Yields while this process is the one runner, false without yielding when another runner holds the lock. A session
  # advisory lock on the job's connection: Postgres drops it when the connection closes, so a worker killed mid-run
  # (deploy, OOM) frees it, and a run still 'running' then is abandoned, see fail_abandoned!. Uncached: the query cache
  # would answer a repeated lock or unlock SELECT without asking Postgres.
  def self.with_runner_lock
    with_connection do |connection|
      lock = ->(function) { uncached { connection.select_value("SELECT #{function}(#{RUNNER_LOCK_KEY})") } }
      return false unless lock.call('pg_try_advisory_lock')

      begin
        yield
      ensure
        lock.call('pg_advisory_unlock')
      end
      true
    end
  end

  ABANDONED = 'The runner stopped mid-run (worker restarted or killed). Check the log, then queue the step again: ' \
              'what was committed stays.'.freeze

  # only while holding the runner lock: no runner is alive then, a 'running' run is left from a dead one
  def self.fail_abandoned!
    where(status: 'running').find_each do |run|
      run.log_writer.puts("!! #{ABANDONED}")
      run.finish!(error: ABANDONED)
    end
  end

  # The unsaved runs of a step for the owner leaving, as the admin page's preview form posts it (step, new_owner_id,
  # groups[], owners[]): the triggers step is a run for each new owner in owners { group label => user id }, the groups
  # left empty stay as they are; the tickets steps are one run, to new_owner_id or the owners by trigger, for the groups.
  def self.build_for(old_owner, form, created_by:)
    attributes = { step: form[:step], old_owner:, created_by: }
    return build_trigger_runs(attributes, form[:owners].to_h) if form[:step] == 'triggers'

    [new(**attributes, new_owner_id: form[:new_owner_id].presence, groups: Array(form[:groups]).compact_blank.presence)]
  end

  def self.build_trigger_runs(attributes, owners)
    owners.compact_blank.group_by(&:last).map do |new_owner_id, pairs|
      new(**attributes, new_owner_id:, groups: pairs.map(&:first).sort)
    end
  end

  def active?
    ACTIVE.include?(status)
  end

  def routed?
    step == 'tickets_routed'
  end

  # the step through Ops::OwnerHandover, a dry run unless dry_run: false; ArgumentError for an unknown agent or group
  def perform(out:, dry_run: true)
    handover = Ops::OwnerHandover.new(old_owner.email, out:)
    case step
    when 'triggers' then handover.reassign_triggers!(to: new_owner.email, groups: groups.presence, dry_run:)
    when 'tickets' then handover.reassign_tickets!(to: new_owner.email, groups: groups.presence, dry_run:)
    when 'tickets_routed' then handover.reassign_tickets_to_routed_owners!(groups: groups.presence, dry_run:)
    end
  end

  # queued -> running, false when another worker started it meanwhile
  def start!
    self.class.where(id:, status: 'queued').update_all(status: 'running', started_at: Time.zone.now, updated_at: Time.zone.now) == 1
  end

  def finish!(error: nil)
    log_writer.flush(force: true)
    update_columns(status: error ? 'failed' : 'done', error:, finished_at: Time.zone.now, updated_at: Time.zone.now)
  end

  # the out: of Ops::OwnerHandover
  def log_writer
    @log_writer ||= LogWriter.new(id)
  end

  # Appends to the log through a connection of its own: reassign_tickets! moves each group in a transaction, the
  # lines written meanwhile would show only after its commit and vanish on its rollback otherwise. Ops::OwnerHandover
  # flushes after every line, the log is written at most once a FLUSH_EVERY.
  class LogWriter
    FLUSH_EVERY = 1.second

    def initialize(run_id)
      @run_id = run_id
      @pending = +''
      @flushed_at = Time.zone.at(0)
    end

    def puts(line)
      @pending << line.to_s << "\n"
    end

    def flush(force: false)
      return if @pending.empty?
      return if !force && Time.zone.now - @flushed_at < FLUSH_EVERY

      @flushed_at = Time.zone.now
      chunk = @pending
      @pending = +''
      Thread.new do
        Ops::OwnerHandoverRun.connection_pool.with_connection do |connection|
          connection.update(Ops::OwnerHandoverRun.sanitize_sql_array(
            ['UPDATE ops_owner_handover_runs SET log = log || ?, updated_at = ? WHERE id = ?', chunk, Time.now.utc, @run_id]
          ))
        end
      end.join
    end
  end
end
