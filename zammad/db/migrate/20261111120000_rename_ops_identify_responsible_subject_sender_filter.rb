class RenameOpsIdentifyResponsibleSubjectSenderFilter < ActiveRecord::Migration[7.2]
  # Zammad 7.2 (GHSA-6wx3-xr2r-5xqf) loads postmaster filters only from Channel::Filter and a
  # pre filter it can't load fails every incoming mail (ops#1370). Per Zammad's
  # BREAKING_CHANGES.md the renamed class goes into state_initial as well as state_current,
  # as the setting validation accepts only the class the setting was created with.
  NAME = '0014_qpostmaster_filter_ops_identify_responsible_subject_sender'.freeze
  OLD_CLASS = 'Ops::IdentifyResponsibleSubjectSender'.freeze
  NEW_CLASS = 'Channel::Filter::OpsIdentifyResponsibleSubjectSender'.freeze

  def up
    rename(OLD_CLASS, NEW_CLASS)
  end

  def down
    rename(NEW_CLASS, OLD_CLASS)
  end

  private

  def rename(from, to)
    setting = Setting.find_by(name: NAME)
    return unless setting

    setting.state_initial = setting.state_initial.merge(value: to) if setting.state_initial[:value] == from
    setting.state_current = setting.state_current.merge(value: to) if setting.state_current[:value] == from
    setting.skip_validate = true
    setting.save!
    Setting.reload
  end
end
