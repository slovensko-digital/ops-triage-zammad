default = {
  analysis: {
    analyzer: {
      default: {
        type: :custom,
        tokenizer: :standard,
        filter: %i[lowercase asciifolding]
      }
    }
  }
}

settings = Models.indexable.each_with_object({}) do |model, out|
  out[model.name] = default
end

Setting.set('es_model_settings', settings)

Setting.create_if_not_exists(
  title:       __('Defines postmaster filter.'),
  name:        '0014_qpostmaster_filter_ops_identify_responsible_subject_sender',
  area:        'Postmaster::PreFilter',
  description: __('Defines postmaster filter to identify responsible subject sender.'),
  options:     {},
  state:       'Ops::IdentifyResponsibleSubjectSender',
  frontend:    false
)
