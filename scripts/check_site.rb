# frozen_string_literal: true
require 'nokogiri'
require 'yaml'
require 'uri'
require 'pathname'

root = File.expand_path(ARGV[0] || '_site')
config = YAML.safe_load(File.read('_config.yml', encoding: 'UTF-8'), aliases: false)
baseurl = config.fetch('baseurl', '')
errors = []
unless File.file?(File.join(root, 'index.html'))
  warn "ERROR: no built index.html in #{root}"
  exit 1
end
html_files = Dir.glob(File.join(root, '**', '*.html'))
docs = html_files.to_h { |f| [f, Nokogiri::HTML5(File.read(f, encoding: 'UTF-8'))] }
site_host = URI.parse(config['url'].to_s).host rescue nil
check_url = lambda do |value, source, label|
  if value.nil? || value.strip.empty? || value == '#'
    errors << "#{source}: empty #{label}"
    next
  end
  next if value.start_with?('mailto:', 'tel:')
  if value.start_with?('https://', 'http://', '//')
    begin
      uri = URI.parse(value.start_with?('//') ? "https:#{value}" : value)
      next unless site_host && uri.host == site_host
      value = uri.request_uri
    rescue URI::InvalidURIError
      errors << "#{source}: malformed URL #{value}"
      next
    end
  elsif value.match?(/\A[a-z][a-z0-9+.-]*:/i)
    errors << "#{source}: unsupported URL scheme: #{value}"
    next
  end
  path_and_query, fragment = value.split('#', 2)
  path = URI::DEFAULT_PARSER.unescape(path_and_query.split('?', 2).first.to_s)
  if path.empty?
    target = source
  elsif path.start_with?('/')
    unless baseurl.empty? || path == baseurl || path.start_with?(baseurl + '/')
      errors << "#{source}: missing baseurl #{baseurl}: #{value}"
      next
    end
    path = path.delete_prefix(baseurl) unless baseurl.empty?
    target = File.expand_path(path.delete_prefix('/'), root)
  else
    target = File.expand_path(path, File.dirname(source))
  end
  target = File.join(target, 'index.html') if File.directory?(target)
  unless target.start_with?(root + File::SEPARATOR) && File.file?(target)
    errors << "#{source}: missing local target #{value}"
    next
  end
  if fragment && !fragment.empty? && target.end_with?('.html')
    fragment = URI::DEFAULT_PARSER.unescape(fragment)
    doc = docs[target] ||= Nokogiri::HTML5(File.read(target, encoding: 'UTF-8'))
    errors << "#{source}: missing fragment ##{fragment} in #{target}" unless doc.css('[id], a[name]').any? { |n| n['id'] == fragment || n['name'] == fragment }
  end
end
docs.each do |file, doc|
  ids = doc.css('[id]').map { |n| n['id'] }
  errors << "#{file}: duplicate HTML id" unless ids.uniq.size == ids.size
  doc.css('[href], [src]').each do |node|
    %w[href src].each { |attr| check_url.call(node[attr], file, attr) if node.key?(attr) }
  end
  doc.css('script[src], img[src], link[rel=stylesheet]').each do |node|
    resource = node['src'] || node['href']
    errors << "#{file}: core asset is remote: #{resource}" if resource.to_s.match?(%r{\A(?:https?:)?//})
  end
  text = doc.text
  errors << "#{file}: template identity/demo/analytics residue" if text.match?(/YaoYao Liu|Your Name|Your Affiliation|minimal-light-theme\.yliu\.me|UA-111540567-4/i) || doc.to_html.match?(/google-analytics\.com|googletagmanager\.com|UA-111540567-4/)
end
Dir.glob(File.join(root, '**', '*.css')).each do |file|
  File.read(file).scan(/url\(\s*['"]?([^)'"\s]+)['"]?\s*\)/).flatten.each { |value| check_url.call(value, file, 'CSS url') }
end
Dir.glob(File.join(root, '**', '*'), File::FNM_DOTMATCH).each do |file|
  next unless File.file?(file)
  relative = Pathname.new(file).relative_path_from(Pathname.new(root)).to_s.tr('\\', '/')
  forbidden = relative.match?(%r{(?:\A|/)(?:vendor|scripts|tests|\.git|\.local|\.tools|html_source_file)(?:/|\z)}) || relative.match?(/\.(?:docx|xlsx|zip|7z|rb|yml|yaml|log|lock|md)\z/i) || relative.match?(/(?:PROFILE_INPUT|CODEX_ACADEMIC_WEBSITE|VALIDATION_REPORT|Gemfile|GOAL\.txt|PROMPT\.txt|START_HERE)/i)
  errors << "Forbidden source/private artifact in output: #{relative}" if forbidden
end
home = docs.fetch(File.join(root, 'index.html'))
if config['ready_for_publication'] != true || home.at_css('.preview-notice')
  errors << 'Draft must use noindex' unless home.at_css('meta[name=robots]')&.[]('content').to_s.include?('noindex')
  errors << 'Draft must not output canonical' if home.at_css('link[rel=canonical]')
else
  canonical = home.at_css('link[rel=canonical]')&.[]('href')
  errors << 'Production canonical does not match configured site URL' unless canonical == "#{config['url']}#{baseurl}/"
  errors << 'Production must not contain noindex' if home.at_css('meta[name=robots]')&.[]('content').to_s.include?('noindex')
end
if errors.empty?
  puts "Built-site checks passed: #{docs.size} HTML documents; local targets, fragments, assets, source isolation, draft SEO. External availability is checked separately."
else
  warn errors.map { |e| "ERROR: #{e}" }.join("\n")
  exit 1
end
