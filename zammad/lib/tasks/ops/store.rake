namespace :ops do
  namespace :store do
    task convert_heic_to_jpg: :environment do
      stores_to_convert = Store.where(
        'preferences ILIKE :heic_pattern OR preferences ILIKE :heif_pattern',
        heic_pattern: '%image/heic%',
        heif_pattern: '%image/heif%'
      ).where(
        'LOWER(filename) LIKE ? OR LOWER(filename) LIKE ?',
        '%.heic',
        '%.heif'
      )

      stores_to_convert.find_each do |store|
        original_content = store.content
        next unless original_content

        image = Rszr::Image.load_data(original_content)
        jpg_content = image.save_data(format: :jpeg)

        new_store_file = Store::File.add(jpg_content)

        store.transaction do
          store.store_file_id = new_store_file.id
          store.size = jpg_content.to_s.bytesize
          store.filename = "#{::File.basename(store.filename, '.*')}.jpg"

          %w[Mime-Type Content-Type mime_type content_type].each do |key|
            store.preferences[key] = 'image/jpeg' if store.preferences.key?(key)
          end

          store.save!
        end
      end
    end
  end
end