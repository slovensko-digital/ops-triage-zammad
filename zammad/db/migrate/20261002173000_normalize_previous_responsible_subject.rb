class NormalizePreviousResponsibleSubject < ActiveRecord::Migration[7.2]
  def up
    # On fresh installs the column is created later by db/seeds/ops_custom_ticket_fields.rb,
    # so there is nothing to normalize yet.
    return unless column_exists?(:tickets, :previous_responsible_subject)

    execute <<~SQL
      UPDATE tickets
      SET previous_responsible_subject = jsonb_build_object(
        'label',
        COALESCE(
          previous_responsible_subject->>'label',
          previous_responsible_subject->>'subject_name',
          previous_responsible_subject->>'name'
        ),
        'value',
        COALESCE(
          NULLIF(previous_responsible_subject->'value', 'null'::jsonb),
          previous_responsible_subject->'id'
        )
      )
      WHERE previous_responsible_subject IS NOT NULL
        AND previous_responsible_subject <> '{}'::jsonb
        AND jsonb_typeof(previous_responsible_subject) = 'object'
        AND NOT (
          previous_responsible_subject ? 'label'
          AND previous_responsible_subject ? 'value'
        )
        AND (
          previous_responsible_subject ? 'value'
          OR previous_responsible_subject ? 'id'
        )
        AND COALESCE(
          previous_responsible_subject->>'label',
          previous_responsible_subject->>'subject_name',
          previous_responsible_subject->>'name'
        ) IS NOT NULL
    SQL
  end

  def down
  end
end
