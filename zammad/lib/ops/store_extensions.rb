module Ops::StoreExtensions
  def set_store_file
    if should_convert_to_jpg?
      self.data = convert_to_jpg(data)
      self.filename = "#{::File.basename(filename, '.*')}.jpg"
      update_content_type_to_jpg
    end

    super
  end

  def should_convert_to_jpg?
    mime_type = preferences['Mime-Type'] || preferences['Content-Type'] || preferences['mime_type'] || preferences['content_type']
    mime_type&.match?(%r{image/(heic|heif)}i)
  end

  def convert_to_jpg(content)
    image = Rszr::Image.load_data(content)
    image.save_data(format: :jpeg)
  end

  def update_content_type_to_jpg
    %w[Mime-Type Content-Type mime_type content_type].each do |key|
      preferences[key] = 'image/jpg' if preferences.key?(key)
    end
  end
end
