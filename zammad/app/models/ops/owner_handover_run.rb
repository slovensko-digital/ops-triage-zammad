# One step of an owner handover queued from the admin page /ops/owner_handover, run by Ops::OwnerHandoverJob at
# run_at with dry_run: false. The step's output goes to log line by line, so the page shows its progress.
#
#   triggers  Ops::OwnerHandover#reassign_triggers!
#   tickets   Ops::OwnerHandover#reassign_tickets!
#   reindex   Ops::OwnerHandover#reindex_tickets! (old_owner_email is the agent whose tickets are reindexed)
class Ops::OwnerHandoverRun < ActiveRecord::Base
  self.table_name = 'ops_owner_handover_runs'

  STEPS = %w[triggers tickets reindex].freeze
  ACTIVE = %w[queued running].freeze

  validates :step, inclusion: { in: STEPS }
  validates :old_owner_email, :run_at, :created_by_id, presence: true
  validates :new_owner_email, presence: true, unless: -> { step == 'reindex' }

  scope :active, -> { where(status: ACTIVE) }
  scope :recent, -> { order(id: :desc) }

  belongs_to :created_by, class_name: 'User'

  def active?
    ACTIVE.include?(status)
  end

  # queued -> running, false when it was cancelled or started by another worker meanwhile
  def start!
    self.class.where(id:, status: 'queued').update_all(status: 'running', started_at: Time.zone.now, updated_at: Time.zone.now) == 1
  end

  def cancel!
    self.class.where(id:, status: 'queued').update_all(status: 'cancelled', finished_at: Time.zone.now, updated_at: Time.zone.now) == 1
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
