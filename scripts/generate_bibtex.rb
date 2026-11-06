# frozen_string_literal: true

# Publication YAML is the editable source; local BibTeX files are generated.
require 'fileutils'
require 'optparse'
require 'uri'
require 'yaml'

check_only = false
OptionParser.new { |p| p.on('--check', 'Report stale files without writing') { check_only = true } }.parse!
root = Dir.pwd
source = File.join(root, '_data', 'publications.yml')
abort 'Run this command from the website root containing _data/publications.yml.' unless File.file?(source)

def tex(value)
  escapes = {
    '\\' => '\\textbackslash{}', '{' => '\\{', '}' => '\\}', '&' => '\\&',
    '%' => '\\%', '#' => '\\#', '_' => '\\_', '$' => '\\$',
    '~' => '\\textasciitilde{}', '^' => '\\textasciicircum{}'
  }
  value.to_s.gsub(/[\\{}&%#_$~^]/) { |character| escapes.fetch(character) }
end

begin
  data = YAML.safe_load(File.read(source, encoding: 'UTF-8'), permitted_classes: [], aliases: false)
  papers = data.fetch('main')
  raise 'main must be a list' unless papers.is_a?(Array)
  outputs = {}
  papers.each_with_index do |paper, index|
    field = "_data/publications.yml: main[#{index}]"
    raise "#{field}: expected a mapping" unless paper.is_a?(Hash)
    link = paper.fetch('links', {})['bibtex']
    next unless link.is_a?(String) && link.start_with?('/assets/files/') && link.end_with?('.bib')

    decoded = URI::DEFAULT_PARSER.unescape(link)
    segments = decoded.delete_prefix('/').split('/')
    unless decoded.start_with?('/assets/files/') && decoded.end_with?('.bib') &&
           !decoded.match?(/[\\\x00?#]/) && segments.none? { |part| ['', '.', '..'].include?(part) }
      raise "#{field}.links.bibtex: unsafe local BibTeX path"
    end
    relative = decoded.delete_prefix('/')
    target = File.expand_path(relative, root)
    files_root = File.join(root, 'assets', 'files')
    raise "#{field}.links.bibtex: path escapes assets/files" unless target.start_with?(files_root + File::SEPARATOR)
    raise "#{field}.links.bibtex: duplicate generated file #{relative}" if outputs.key?(target)

    %w[id title venue year].each do |key|
      raise "#{field}.#{key}: value required for BibTeX" if paper[key].nil? || paper[key].to_s.strip.empty?
    end
    raise "#{field}.id: invalid BibTeX key" unless paper['id'].to_s.match?(/\A[a-z][a-z0-9-]*\z/)
    authors = paper['authors']
    unless authors.is_a?(Array) && !authors.empty? && authors.all? { |a| a.is_a?(Hash) && a['name'].is_a?(String) && !a['name'].strip.empty? }
      raise "#{field}.authors: complete name list required for BibTeX"
    end
    citation = paper.fetch('citation', {})
    raise "#{field}.citation: expected a mapping" unless citation.is_a?(Hash)
    fields = {
      'title' => "{#{tex(paper['title'])}}", # Protect exact title/acronym capitalization.
      'author' => authors.map { |author| tex(author['name']) }.join(' and '),
      'journal' => tex(paper['venue']), 'year' => tex(paper['year'])
    }
    %w[volume number pages].each do |key|
      value = citation[key]
      fields[key] = tex(value) unless value.nil? || value.to_s.empty?
    end
    doi_url = paper.fetch('links', {})['doi'].to_s
    unless doi_url.empty?
      doi = doi_url.sub(%r{\Ahttps?://(?:dx\.)?doi\.org/}i, '')
      raise "#{field}.links.doi: expected a DOI resolver URL" if doi == doi_url
      fields['doi'] = tex(URI::DEFAULT_PARSER.unescape(doi))
    end
    url = doi_url.empty? ? paper.fetch('links', {})['paper'].to_s : doi_url
    fields['url'] = tex(url) unless url.empty?
    expected = "% Generated from _data/publications.yml; do not edit by hand.\n"
    expected += "@article{#{paper['id']},\n"
    fields.each { |key, value| expected += "  #{key} = {#{value}},\n" }
    expected += "}\n"
    outputs[target] = [relative, expected.encode(Encoding::UTF_8)]
  end

  stale = outputs.filter_map do |target, (relative, expected)|
    next if File.file?(target) && File.binread(target) == expected.b
    if check_only
      "ERROR: #{relative}: missing or stale; run bundle exec ruby scripts/generate_bibtex.rb"
    else
      FileUtils.mkdir_p(File.dirname(target))
      File.binwrite(target, expected)
      nil
    end
  end
  abort stale.join("\n") unless stale.empty?
  puts "BibTeX #{check_only ? 'check' : 'generation'} passed; #{outputs.size} local resources."
rescue Psych::Exception, KeyError, TypeError, RuntimeError => error
  abort "ERROR: #{error.message}"
end
