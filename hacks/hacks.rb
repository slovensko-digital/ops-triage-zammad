#!/usr/bin/env ruby
require 'fileutils'

def replace_file_with(file, &block)
  File.write(file, block.call(File.read(file)))
end

replace_file_with('app/views/layouts/application.html.erb') do |content|
  content.gsub(/<\/head>/, <<-HACK)
  <%= stylesheet_link_tag "/assets/ops-application.css?v#{content.hash}" %>
</head>
  HACK
end

replace_file_with('app/views/layouts/desktop.html.erb') do |content|
  content.gsub(/<\/head>/, <<-HACK)
  <%= stylesheet_link_tag "/assets/ops-desktop.css?v#{content.hash}" %>
</head>
  HACK
end

replace_file_with('app/views/layouts/mobile.html.erb') do |content|
  content.gsub(/<\/head>/, <<-HACK)
  <%= stylesheet_link_tag "/assets/ops-mobile.css?v#{content.hash}" %>
</head>
  HACK
end
