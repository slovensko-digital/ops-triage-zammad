# Hands over the triggers and tickets of an agent who stops volunteering, group by group: the 700 routing triggers
# set each new ticket's group and owner, a trigger moves as a whole and tickets move with their group.
#
#   1. report             the old owner's triggers and tickets by group, with commands moving them to the routed owner
#   2. reassign_triggers! points the triggers to the new owner, who gets full access to the groups
#   3. reassign_tickets!  moves the tickets (closed ones too, they can be reopened), without notifications or triggers,
#                         one transaction per group in the order listed, then reindexes the group's tickets itself;
#                         refused while an active trigger still routes the group to the old owner;
#                         reassign_tickets_to_routed_owners! does it for each group to the agent it is routed to now
#   4. reindex_tickets!   reindexes the agent's tickets, after a reassign_tickets! stopped while reindexing
#
# Test tickets (customers in test_customer_logins:) are never moved. The reassign methods are dry runs unless
# dry_run: false; groups: limits them to some groups, named as the report shows them ("Bratislava / Devín").
# preview: true words the dry runs for the Ops pages, as a preview applied from the page.
#
#   h = Ops::OwnerHandover.new('old@example.org')
#   h.report
#   h.reassign_triggers!(to: 'new@example.org', groups: ['Pezinok'], dry_run: false)
#   h.reassign_tickets!(to: 'new@example.org', groups: ['Pezinok'], dry_run: false)
#   h.reassign_tickets_to_routed_owners!(dry_run: false)
#   Ops::OwnerHandover.new('new@example.org').reindex_tickets!(groups: ['Pezinok'])
class Ops::OwnerHandover
  include Ops::OwnerHandoverSupport

  attr_reader :old_owner

  def initialize(old_owner_email, out: $stdout, all_ids: false, test_customer_logins: DEFAULT_TEST_CUSTOMER_LOGINS,
                 preview: false)
    setup_handover_support(out:, all_ids:, test_customer_logins:)
    @preview = preview
    @old_owner = find_agent!(old_owner_email)
  end

  # every trigger setting the old owner, not only the 700 ones
  def triggers(groups: nil)
    selected = Trigger.order(:name).select { |trigger| trigger_owner_id(trigger) == old_owner.id }
    return selected unless groups

    ids = find_groups!(groups).map(&:id)
    selected.select { |trigger| ids.include?(trigger_group_id(trigger)) }
  end

  def tickets(groups: nil)
    without_test_tickets(owned_tickets(groups:)).order(:id)
  end

  def test_tickets(groups: nil)
    only_test_tickets(owned_tickets(groups:)).order(:id)
  end

  def report
    all_triggers = triggers
    test_rows = test_tickets.pluck(:group_id, :id, :created_at)
    say "Old owner: #{describe(old_owner)}"
    say ''
    say_test_tickets_note(test_rows.size)
    say ''

    say "Triggers setting the old owner as the ticket owner (#{all_triggers.size}):"
    all_triggers.each do |trigger|
      say "  ##{trigger.id} #{trigger.active ? 'active' : 'INACTIVE'} | group #{group_name(trigger_group_id(trigger))} | " \
          "municipalities #{trigger_municipalities(trigger).inspect} | #{trigger.name}"
    end
    other = other_triggers_mentioning_old_owner(all_triggers)
    if other.any?
      say ''
      say 'Other triggers mentioning the old owner, check them by hand:'
      other.each { |trigger| say "  ##{trigger.id} #{trigger.name}" }
    end

    say ''
    rows = tickets.pluck(:group_id, :ops_state, :id, :created_at)
    say "Tickets owned by the old owner (#{rows.size}, #{test_rows.size} test tickets omitted), by group and ops_state, with the owner the group is routed to now:"
    routes = routed_owners_by_group
    commands = Hash.new { |hash, key| hash[key] = [] }
    still_routed = []
    by_group(rows).each do |group_id, group_rows|
      label = group_name(group_id)
      routed = routes.fetch(group_id, {})
      say "  #{label}: #{group_rows.size} | #{describe_routing(routed, old_owner_id: old_owner.id)}"
      group_rows.group_by { |_group_id, state, _id, _created_at| state.presence || '(empty)' }.sort.each do |state, state_rows|
        say "    #{state}: #{state_rows.size} | ticket ids #{ticket_ids(state_rows)}"
      end

      routed_owner_id = single_routed_owner_id(routed)
      if routed_owner_id == old_owner.id
        still_routed << label
      elsif routed_owner_id
        add_tickets_command(commands, old_owner, user(routed_owner_id), label, indent: '    ')
      end
    end

    if test_rows.any?
      say ''
      say "Test tickets owned by the old owner, omitted, never moved (#{test_rows.size}):"
      by_group(test_rows).each do |group_id, group_rows|
        say "  #{group_name(group_id)}: #{group_rows.size} | ticket ids #{ticket_ids(group_rows)}"
      end
    end

    if still_routed.any?
      say ''
      say 'Groups still routed to the old owner, hand over their triggers first (pick NEW_EMAIL), then run the report again:'
      say "  rake 'ops:owner_handover:triggers[#{old_owner.email},NEW_EMAIL]' GROUPS='#{still_routed.join(';')}'"
    end

    say_tickets_commands('Commands moving the tickets to the routed owner', commands)

    { triggers: all_triggers, tickets: rows, test_tickets: test_rows }
  end

  # what report says by group, for the admin page: routes are { owner id => trigger ids } of the active triggers of the
  # group, routed_owner the agent they route it to when there is a single one other than the old owner. status is the
  # handover step the group is at:
  #
  #   triggers   the old owner's trigger is still there, hand it over to the new owner first
  #   tickets    the trigger routes the group to someone else, the old owner's tickets go to them
  #   attention  tickets left but no single active trigger routes the group, fix the triggers in Zammad
  #   done       only test tickets left, they stay with the old owner
  GroupOverview = Struct.new(:group_id, :label, :triggers, :tickets, :test_tickets, :routes, :routed_owner,
                             keyword_init: true) do
    def status
      if triggers.any? then :triggers
      elsif tickets.zero? then :done
      elsif routed_owner then :tickets
      else :attention
      end
    end
  end

  def groups_overview(groups: nil)
    triggers_by_group = triggers(groups:).group_by { |trigger| trigger_group_id(trigger) }
    ticket_counts = without_test_tickets(owned_tickets(groups:)).group(:group_id).count
    test_counts = only_test_tickets(owned_tickets(groups:)).group(:group_id).count
    routes = routed_owners_by_group

    (triggers_by_group.keys | ticket_counts.keys | test_counts.keys).compact.map do |group_id|
      routed = routes.fetch(group_id, {})
      routed_owner_id = single_routed_owner_id(routed)
      GroupOverview.new(
        group_id:,
        label: group_name(group_id),
        triggers: triggers_by_group.fetch(group_id, []),
        tickets: ticket_counts.fetch(group_id, 0),
        test_tickets: test_counts.fetch(group_id, 0),
        routes: routed,
        routed_owner: routed_owner_id && routed_owner_id != old_owner.id ? user(routed_owner_id) : nil
      )
    end.sort_by(&:label)
  end

  def reassign_triggers!(to:, groups: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = triggers(groups:)
    warn_about_groups(groups, selected.map { |trigger| trigger_group_id(trigger) }, 'triggers')

    say_plan('Triggers', new_owner, selected.size, dry_run:)
    selected.each do |trigger|
      new_name = renamed(trigger.name, new_owner)
      say "  ##{trigger.id} #{trigger.name}"
      say "    -> #{new_name}" if new_name != trigger.name
      if new_name == trigger.name && mentions_old_owner?(trigger.name)
        say "    !! the name does not end with #{agent_name(old_owner).inspect}, it stays as it is"
      end
      grant_group_access(new_owner, trigger_group_id(trigger), dry_run:)
      next if dry_run

      trigger.update!(name: new_name, perform: perform_with_owner(trigger.perform, new_owner), updated_by_id: 1)
    end
    say_dry_run_hint if dry_run && selected.any?
    selected
  end

  def reassign_tickets!(to:, groups: nil, dry_run: true)
    new_owner = find_agent!(to)
    selected = tickets(groups:).to_a
    warn_about_groups(groups, selected.map(&:group_id), 'tickets')
    still_routed = routed_group_ids(triggers(groups:))
    if still_routed.any?
      raise ArgumentError, "Active triggers still route groups #{still_routed.map { |id| group_name(id) }.inspect} " \
                           "to #{describe(old_owner)}, run reassign_triggers! for them first"
    end

    say_plan('Tickets', new_owner, selected.size, dry_run:)
    by_group(selected.map { |ticket| [ticket.group_id, ticket.id, ticket.created_at] }).each do |group_id, group_rows|
      say "  group #{group_name(group_id)}: #{group_rows.size} | ticket ids #{ticket_ids(group_rows)}"
      grant_group_access(new_owner, group_id, dry_run:)
    end
    test_rows = test_tickets(groups:).pluck(:id, :created_at)
    say ''
    say_test_tickets_note(test_rows.size)
    say "  staying with the old owner | ticket ids #{ticket_ids(test_rows)}" if test_rows.any?
    if dry_run
      say_dry_run_hint if selected.any?
      return selected
    end

    say ''
    say "Moving #{delimited(selected.size)} tickets to #{describe(new_owner)}, each group committed on its own..."
    groups_to_move = selected.group_by(&:group_id).sort_by { |group_id, _tickets| group_name(group_id) }
    moved = 0
    groups_to_move.each.with_index(1) do |(group_id, group_tickets), index|
      say ''
      say "Group #{index} / #{groups_to_move.size} #{group_name(group_id)}: #{delimited(group_tickets.size)} tickets"
      move_tickets(group_tickets, new_owner)
      moved += group_tickets.size
      say "  Committed, #{delimited(moved)} / #{delimited(selected.size)} tickets moved"
      reindex(group_tickets.map(&:id), owner: new_owner)
    end
    say ''
    say "Moved #{selected.size} tickets, #{tickets.count} left with #{describe(old_owner)} " \
        "(and #{test_tickets.count} test tickets)."
    selected
  end

  # reassign_tickets! for each group to the agent its trigger routes it to now, read when it runs; the groups not routed
  # to a single other agent are skipped and listed
  def reassign_tickets_to_routed_owners!(groups: nil, dry_run: true)
    overview = groups_overview(groups:).select { |group| group.tickets.positive? }
    ready, skipped = overview.partition { |group| group.status == :tickets }

    if skipped.any?
      say "Skipped, hand over the trigger or fix the routing first (#{skipped.size}):"
      skipped.each { |group| say "  #{group.label}: #{describe_routing(group.routes, old_owner_id: old_owner.id)}" }
      say ''
    end
    if ready.empty?
      say 'No group with tickets ready to move to its routed owner.'
      return []
    end

    ready.group_by(&:routed_owner).flat_map do |owner, owner_groups|
      say "== #{owner_groups.size} #{owner_groups.one? ? 'group' : 'groups'} routed to #{describe(owner)}"
      moved = reassign_tickets!(to: owner.email, groups: owner_groups.map(&:label), dry_run:)
      say ''
      moved
    end
  end

  # the tickets of the agent this handover was created with, test tickets too, for the new owner after a
  # reassign_tickets! stopped while reindexing; safe to run again
  def reindex_tickets!(groups: nil)
    rows = owned_tickets(groups:).order(:id).pluck(:id, :group_id)
    warn_about_groups(groups, rows.map(&:last), 'tickets')
    say "Reindexing #{delimited(rows.size)} tickets of #{describe(old_owner)}"
    reindex(rows.map(&:first))
  end

  private

  # one transaction, so a failure rolls back only these tickets and the groups moved before stay moved.
  # TransactionDispatcher.reset drops the ticket changes from the EventBuffer: no trigger runs and no TransactionJob
  # is queued per ticket (left there, a later Transaction.execute in the same console session would dispatch them,
  # notifying the new owner after all). No search index job is queued either, reindex does it right after the commit.
  def move_tickets(tickets, new_owner)
    Ops::TicketExtensions.without_search_index_update do
      Transaction.execute(disable_notification: true, disable: %w[Transaction::Notification Transaction::Trigger]) do
        tickets.each.with_index(1) do |ticket, done|
          ticket.update!(owner_id: new_owner.id)
          say_progress(done, tickets.size)
        end
        TransactionDispatcher.reset
        say '  Finishing the transaction...'
      end
    end
  end

  # what SearchIndexJob does for each ticket, in this process instead of 2 queued jobs per ticket; a failed ticket
  # is reported and skipped, reindex_tickets! retries
  def reindex(ids, owner: old_owner)
    unless SearchIndexBackend.enabled?
      say '  Search index off, nothing to reindex'
      return
    end

    say "  Reindexing #{delimited(ids.size)} tickets..."
    failed = []
    Ticket.where(id: ids).find_each.with_index(1) do |ticket, done|
      begin
        ticket.search_index_update_backend
      rescue => e
        failed << ticket.id
        say "  !! ticket #{ticket.id} not reindexed: #{e.class} #{e.message.truncate(200)}"
      end
      say_progress(done, ids.size)
    end
    return say('  Reindexed') if failed.empty?

    say "  !! #{delimited(failed.size)} tickets not reindexed, ids #{failed.join(', ')}; retry with " \
        "rake 'ops:owner_handover:reindex[#{owner.email}]'"
  end

  def say_plan(what, new_owner, count, dry_run:)
    prefix = @preview ? '[PREVIEW] ' : '[DRY RUN] '
    say "#{dry_run ? prefix : ''}#{what} of #{describe(old_owner)} -> #{describe(new_owner)}: #{count}"
  end

  PROGRESS_EVERY = 100

  # "  100 / 3_632 tickets (2.8%)"
  def say_progress(done, total)
    return unless (done % PROGRESS_EVERY).zero? || done == total

    say "  #{delimited(done)} / #{delimited(total)} tickets (#{(100.0 * done / total).round(1)}%)"
  end

  def delimited(number)
    ActiveSupport::NumberHelper.number_to_delimited(number, delimiter: '_')
  end

  def say_dry_run_hint
    say ''
    say @preview ? 'Nothing changed, apply it below.' : 'Nothing changed, run again with dry_run: false to apply.'
  end

  def owned_tickets(groups: nil)
    scope = Ticket.where(owner_id: old_owner.id)
    scope = scope.where(group_id: find_groups!(groups).map(&:id)) if groups
    scope
  end

  def find_agent!(email)
    user = User.find_by(email: email.to_s.strip.downcase)
    raise ArgumentError, "No user with email #{email.inspect}" unless user
    raise ArgumentError, "#{describe(user)} is not an agent" unless agent?(user)

    user
  end

  def routed_group_ids(triggers)
    triggers.select(&:active).map { |trigger| trigger_group_id(trigger) }.uniq
  end

  # "Bratislava / Devín" or "Bratislava::Devín"; raises ArgumentError for an unknown name
  def find_groups!(names)
    stored = names.to_h { |name| [name, name.to_s.strip.split(GROUP_SEPARATOR.strip).map(&:strip).join('::')] }
    groups = Group.where(name: stored.values.uniq).index_by(&:name)
    unknown = stored.reject { |_name, value| groups.key?(value) }.keys
    if unknown.any?
      messages = unknown.map do |name|
        suggestions = suggest_groups(name)
        "#{name.inspect}#{suggestions.any? ? " (did you mean #{suggestions.map(&:inspect).join(' or ')}?)" : ''}"
      end
      raise ArgumentError, "Not a group in Triage: #{messages.join(', ')}"
    end

    stored.values.uniq.map { |value| groups[value] }
  end

  # ignores case and diacritics and matches the last part: "Devin" finds "Bratislava / Devín"
  def suggest_groups(name)
    wanted = normalized(name.to_s.gsub('::', GROUP_SEPARATOR))
    Group.all.map { |group| group_label(group) }.select do |label|
      normalized(label) == wanted || normalized(label.split(GROUP_SEPARATOR).last) == wanted
    end
  end

  def normalized(value)
    ActiveSupport::Inflector.transliterate(value.to_s).downcase.gsub(/\s+/, ' ').strip
  end

  # keep the trigger's format: the admin UI saves string ids with value_completion, the portal integers without it
  def perform_with_owner(perform, new_owner)
    owner = perform['ticket.owner_id'].dup
    owner['value'] = owner['value'].is_a?(String) ? new_owner.id.to_s : new_owner.id
    owner['value_completion'] = "#{agent_name(new_owner)} <#{new_owner.email}>" if owner.key?('value_completion')
    perform.merge('ticket.owner_id' => owner)
  end

  def other_triggers_mentioning_old_owner(owner_triggers)
    old_id = old_owner.id.to_s
    (Trigger.all - owner_triggers).select do |trigger|
      conditions_of(trigger.condition).any? { |name, spec| name == 'ticket.owner_id' && Array(spec['value']).map(&:to_s).include?(old_id) }
    end
  end

  def warn_about_groups(groups, found_group_ids, what)
    return unless groups

    find_groups!(groups).each do |group|
      next if found_group_ids.include?(group.id)

      say "  !! #{describe(old_owner)} has no #{what} in group #{group_label(group).inspect}"
    end
  end

  def renamed(name, new_owner)
    old_suffix = " #{agent_name(old_owner)}"
    return name unless name.end_with?(old_suffix)

    "#{name.delete_suffix(old_suffix)} #{agent_name(new_owner)}"
  end

  # the name has the old owner's first or last name, ignoring case and diacritics, so it likely meant to end with
  # their name ("Anna Zelená"); a name without an agent in it ("... Magistrát na základe ulíc") does not
  def mentions_old_owner?(name)
    words = normalized(name).split
    [old_owner.firstname, old_owner.lastname].compact_blank.any? { |part| (normalized(part).split - words).empty? }
  end

  def grant_group_access(user, group_id, dry_run:)
    group = Group.find_by(id: group_id)
    return if group.nil? || user.group_access?(group.id, 'full')

    say "    + #{describe(user)} gets full access to group #{group_label(group)}"
    return if dry_run

    user.group_names_access_map = user.group_names_access_map.merge(group.name => ['full'])
    user.save!
  end
end
