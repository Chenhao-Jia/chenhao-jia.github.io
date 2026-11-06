# frozen_string_literal: true
require 'yaml'
require 'date'
require 'uri'
require 'optparse'

mode = 'preview'
OptionParser.new { |p| p.on('--mode MODE', %w[preview production]) { |v| mode = v } }.parse!
# Run from the website root. Dir.pwd retains UTF-8 paths on Windows, while
# RubyInstaller can decode __dir__ through a legacy code page under Bundler.
ROOT = Dir.pwd
abort 'Run this command from the academic-site directory.' unless File.file?(File.join(ROOT, '_config.yml'))
errors = []
read_yaml = lambda do |relative|
  YAML.safe_load(File.read(File.join(ROOT, relative), encoding: 'UTF-8'), permitted_classes: [Date], aliases: false)
rescue Psych::Exception, Errno::ENOENT => e
  errors << "#{relative}: #{e.message}"
  nil
end
config = read_yaml.call('_config.yml') || {}
profile = read_yaml.call('_data/profile.yml') || {}
pub_data = read_yaml.call('_data/publications.yml') || {}
projects = read_yaml.call('_data/projects.yml') || []
news = read_yaml.call('_data/news.yml') || []
education = read_yaml.call('_data/education.yml') || []
unless [config, profile, pub_data].all? { |v| v.is_a?(Hash) }
  warn 'Configuration/profile/publications must be YAML mappings.'
  exit 1
end
present = ->(v) { v.is_a?(String) && !v.strip.empty? }
text = lambda do |value, field, required = true|
  errors << "#{field}: #{required ? 'nonempty text required' : 'must be text'}" unless (value.nil? && !required) || (value.is_a?(String) && (!required || !value.strip.empty?))
end
url = lambda do |value, field, optional = true|
  next if optional && (value.nil? || value == '')
  unless present.call(value)
    errors << "#{field}: URL must be nonempty text"
    next
  end
  if value.start_with?('/') && !value.start_with?('//')
    decoded = URI::DEFAULT_PARSER.unescape(value.split(/[?#]/, 2).first)
    path = File.expand_path(decoded.delete_prefix('/'), ROOT)
    if decoded.split('/').include?('..') || !path.start_with?(ROOT + File::SEPARATOR)
      errors << "#{field}: local path escapes the site"
    elsif !File.file?(path)
      errors << "#{field}: local file not found: #{decoded}"
    end
  else
    begin
      uri = URI.parse(value)
      valid = %w[https http].include?(uri.scheme) && present.call(uri.host) && !uri.userinfo && !value.match?(/[\s<>]/)
      fake = uri.host.to_s.match?(/(?:^|\.)(?:example\.(?:com|org|net)|localhost)$|\.invalid$|\.test$/i)
      generic = value.match?(%r{\Ahttps?://(?:github\.com|scholar\.google\.[^/]+|orcid\.org|dblp\.org)/?(?:\?.*)?\z}i)
      errors << "#{field}: invalid, placeholder, or generic profile URL: #{value}" unless valid && !fake && !generic
    rescue URI::InvalidURIError
      errors << "#{field}: invalid URL: #{value}"
    end
  end
end
profile.each do |key, value|
  text.call(value, "_data/profile.yml: #{key}", false) if %w[name_en name_zh position affiliation department advisor_name advisor_url email avatar bio_en bio_zh].include?(key)
end
errors << '_data/profile.yml: position must remain Ph.D. Student unless explicitly confirmed' unless profile['position'] == 'Ph.D. Student'
%w[content_confirmed email_public].each do |key|
  errors << "_data/profile.yml: #{key} must be true or false" unless [true, false].include?(profile[key])
end
if profile['email_public'] == true
  errors << '_data/profile.yml: valid public email required' unless profile['email'].to_s.match?(/\A[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+\z/)
elsif present.call(profile['email'])
  errors << '_data/profile.yml: remove non-public email from publishable source; retain it only in private input'
end
url.call(profile['advisor_url'], '_data/profile.yml: advisor_url')
url.call(profile['avatar'], '_data/profile.yml: avatar')
interests = profile['research_interests']
if interests.is_a?(Array)
  interests.each_with_index { |v, i| text.call(v, "_data/profile.yml: research_interests[#{i}]") }
else
  errors << '_data/profile.yml: research_interests must be a list'
end
if profile['links'].is_a?(Hash)
  profile['links'].each do |key, value|
    errors << "_data/profile.yml: links.#{key}: unknown link type" unless %w[google_scholar orcid dblp github cv].include?(key)
    url.call(value, "_data/profile.yml: links.#{key}")
  end
else
  errors << '_data/profile.yml: links must be a mapping'
end
papers = pub_data['main']
unless papers.is_a?(Array)
  errors << '_data/publications.yml: main must be a list'
  papers = []
end
ids = []
papers.each_with_index do |paper, index|
  field = "_data/publications.yml: main[#{index}]"
  unless paper.is_a?(Hash)
    errors << "#{field}: expected mapping"
    next
  end
  %w[id title venue].each { |key| text.call(paper[key], "#{field}.#{key}") }
  errors << "#{field}.id: use a unique lowercase slug (letters, digits, hyphens)" unless paper['id'].to_s.match?(/\A[a-z][a-z0-9-]*\z/)
  errors << "#{field}.id: duplicate #{paper['id']}" if ids.include?(paper['id'])
  ids << paper['id']
  errors << "#{field}.year: four-digit integer required (1900..#{Date.today.year + 1})" unless paper['year'].is_a?(Integer) && (1900..Date.today.year + 1).cover?(paper['year'])
  errors << "#{field}.status: use published / accepted / preprint; do not expose submitted work" unless %w[published accepted preprint].include?(paper['status'])
  authors = paper['authors']
  if authors.is_a?(Array) && !authors.empty?
    authors.each_with_index do |author, a|
      unless author.is_a?(Hash)
        errors << "#{field}.authors[#{a}]: expected name/self mapping"
        next
      end
      text.call(author['name'], "#{field}.authors[#{a}].name")
      errors << "#{field}.authors[#{a}].self: explicit true/false required" unless [true, false].include?(author['self'])
    end
  else
    errors << "#{field}.authors: complete author list required"
  end
  if paper['links'].is_a?(Hash)
    paper['links'].each do |key, value|
      errors << "#{field}.links.#{key}: unknown resource type" unless %w[paper code slides bibtex doi].include?(key)
      url.call(value, "#{field}.links.#{key}")
    end
  else
    errors << "#{field}.links: mapping required (may be empty)"
  end
  text.call(paper['note'], "#{field}.note", false)
end
{ 'projects' => projects, 'news' => news, 'education' => education }.each do |kind, entries|
  unless entries.is_a?(Array)
    errors << "_data/#{kind}.yml: expected list"
    next
  end
  entries.each_with_index do |entry, index|
    field = "_data/#{kind}.yml: [#{index}]"
    unless entry.is_a?(Hash)
      errors << "#{field}: expected mapping"
      next
    end
    required = { 'projects' => %w[name description], 'news' => %w[title], 'education' => %w[period degree] }.fetch(kind)
    required.each { |key| text.call(entry[key], "#{field}.#{key}") }
    if kind == 'projects'
      if entry['links'].is_a?(Hash)
        entry['links'].each { |key, value| url.call(value, "#{field}.links.#{key}", false) }
      else
        errors << "#{field}.links: mapping required"
      end
    elsif kind == 'news'
      begin
        Date.iso8601(entry['date'].to_s)
      rescue ArgumentError
        errors << "#{field}.date: use YYYY-MM-DD"
      end
      url.call(entry['url'], "#{field}.url")
    else
      %w[institution department].each { |key| text.call(entry[key], "#{field}.#{key}", false) }
    end
  end
end
errors << '_config.yml: ready_for_publication must be true or false' unless [true, false].include?(config['ready_for_publication'])
if mode == 'production'
  errors << '_config.yml: ready_for_publication is false; 待补齐或确认资料' unless config['ready_for_publication'] == true
  errors << '_data/profile.yml: content_confirmed must be true after owner review' unless profile['content_confirmed'] == true
  %w[name_en bio_en].each { |key| text.call(profile[key], "_data/profile.yml: #{key}") }
  username = config['github_username'].to_s
  if username.match?(/\A[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?\z/)
    expected_url = "https://#{username.downcase}.github.io"
    errors << "_config.yml: url must be #{expected_url} for this user site" unless config['url'] == expected_url
  else
    errors << '_config.yml: confirmed GitHub username and corresponding url required'
  end
  errors << '_config.yml: baseurl must be empty for a user site' unless config['baseurl'] == ''
  errors << '_config.yml: production cannot use preview_mode' if config['preview_mode'] == true
  combined = profile.values.grep(String).join('\n') + papers.map { |p| p.is_a?(Hash) ? [p['title'], p['venue']].join(' ') : '' }.join('\n')
  errors << 'Production content contains placeholder/template text' if combined.match?(/Your Name|Your Affiliation|\bTODO\b|\bTBD\b|YaoYao Liu|minimal-light-theme\.yliu\.me|UA-111540567-4/i)
  errors << '_data/profile.yml: replace the placeholder public name' if profile['name_en'].to_s.match?(/\A(?:Academic profile|Your Name|Name here|Anonymous)\z/i)
  errors << '_data/profile.yml: replace the placeholder biography' if profile['bio_en'].to_s.match?(/will be added|awaiting.*confirmation|placeholder/i)
end
if errors.empty?
  puts "Content validation passed (#{mode}); #{papers.size} publications."
else
  warn errors.map { |e| "ERROR: #{e}" }.join("\n")
  exit 1
end
