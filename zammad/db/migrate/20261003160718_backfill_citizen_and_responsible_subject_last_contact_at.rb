class BackfillCitizenAndResponsibleSubjectLastContactAt < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

    Ticket
      .where(origin: 'portal', citizen_last_contact_at: nil)
      .update_all(<<~SQL.squish)
        citizen_last_contact_at = (
          SELECT MAX(article.created_at)
          FROM ticket_articles article
          WHERE article.ticket_id = tickets.id
            AND article.internal = false
            AND article.sender_id = #{Ticket::Article::Sender.find_by_name("Customer").id}
            AND article.type_id = #{Ticket::Article::Type.find_by_name("web").id}
            AND article.id != (
              SELECT MIN(first_article.id)
              FROM ticket_articles first_article
              WHERE first_article.ticket_id = tickets.id
            )
        )
      SQL

    Ticket
      .where(origin: 'portal', responsible_subject_last_contact_at: nil)
      .update_all(<<~SQL.squish)
        responsible_subject_last_contact_at = (
          SELECT MAX(article.created_at)
          FROM ticket_articles article
          WHERE article.ticket_id = tickets.id
            AND article.internal = false
            AND article.sender_id = #{Ticket::Article::Sender.find_by_name("Customer").id}
            AND article.type_id IN (
              #{Ticket::Article::Type.find_by_name("email").id},
              #{Ticket::Article::Type.find_by_name("note").id}
            )
            AND article.id != (
              SELECT MIN(first_article.id)
              FROM ticket_articles first_article
              WHERE first_article.ticket_id = tickets.id
            )
        )
      SQL
  end

  def down
  end
end
