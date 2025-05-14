class AsciifoldingEs < ActiveRecord::Migration[7.1]
  def up
    return unless Setting.exists?(name: 'system_init_done')

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
  end

  def down
    Settings.set('es_model_settings', {})
  end
end
