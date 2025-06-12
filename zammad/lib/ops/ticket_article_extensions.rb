module Ops::TicketArticleExtensions
  def body_as_html
    return '' if !body

    clean_body = body.gsub("[[ops portal]]", "").gsub("[[pre zodpovedny subjekt]]", "")

    return clean_body if content_type && content_type =~ %r{text/html}i

    clean_body.text2html
  end
end
