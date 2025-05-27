class AddOpsEmailFollowUpParser < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       __('Defines postmaster filter.'),
      name:        '0014_qpostmaster_filter_ops_identify_responsible_subject_sender',
      area:        'Postmaster::PreFilter',
      description: __('Defines postmaster filter to identify responsible subject sender.'),
      options:     {},
      state:       'Ops::IdentifyResponsibleSubjectSender',
      frontend:    false
    )
  end

  def down
    Setting.where(name: '0014_qpostmaster_filter_ops_identify_responsible_subject_sender').destroy_all
  end
end
