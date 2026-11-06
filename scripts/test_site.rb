# frozen_string_literal: true

# Regression fixtures are generated only inside an automatically removed OS
# temporary directory. Formal _data and the normal _site are never changed.
require "bundler"
require "fileutils"
require "find"
require "nokogiri"
require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

# Run from the website root, as documented. RubyInstaller can corrupt __dir__
# when Bundler loads a relative script below a non-ASCII Windows ancestor;
# Dir.pwd preserves its UTF-8 filesystem path on the same machine.
ROOT = Dir.pwd
abort "Run this script from the website root (containing _config.yml)." unless File.file?(File.join(ROOT, "_config.yml"))
OMIT_DIRECTORIES = %w[.git .bundle vendor _site .local .tools .jekyll-cache .sass-cache tests].freeze
BUNDLE_COMMAND = [RbConfig.ruby, Gem.bin_path("bundler", "bundle")].freeze
COMMAND_ENV = {
  "BUNDLE_GEMFILE" => File.join(ROOT, "Gemfile"),
  "BUNDLE_PATH" => Bundler.bundle_path.to_s,
  "JEKYLL_ENV" => "development"
}.freeze

def assert!(condition, message)
  raise message unless condition
end

def run!(directory, *arguments, success: true, diagnostic: nil, environment: {})
  output, status = Open3.capture2e(COMMAND_ENV.merge(environment), *BUNDLE_COMMAND, "exec", *arguments,
                                 chdir: directory)
  expected = success ? status.success? : !status.success?
  assert!(expected, "Unexpected exit #{status.exitstatus} for #{arguments.join(' ')}\n#{output}")
  assert!(output.include?(diagnostic), "Missing diagnostic #{diagnostic.inspect}:\n#{output}") if diagnostic
  output
end

def ruby!(directory, script, *arguments, **options)
  run!(directory, RbConfig.ruby, File.join(directory, script), *arguments, **options)
end

def write_yaml(directory, path, value)
  target = File.join(directory, path)
  FileUtils.mkdir_p(File.dirname(target))
  File.write(target, YAML.dump(value), encoding: "UTF-8")
end

def copy_source(destination)
  Find.find(ROOT) do |path|
    next if path == ROOT

    relative = path.delete_prefix(ROOT + File::SEPARATOR)
    basename = File.basename(path)
    if File.directory?(path) && OMIT_DIRECTORIES.include?(basename)
      Find.prune
    end
    next if File.symlink?(path)
    next if File.file?(path) && relative !~ %r{[/\\]} &&
            (basename.end_with?(".md", ".txt", ".lock") && !%w[index.md 404.md robots.txt].include?(basename))

    target = File.join(destination, relative)
    if File.directory?(path)
      FileUtils.mkdir_p(target)
    else
      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.copy_file(path, target)
    end
  end
end

def build!(directory)
  ruby!(directory, "scripts/validate_content.rb", "--mode", "preview")
  run!(directory, RbConfig.ruby, Gem.bin_path("jekyll", "jekyll"), "build",
       "--config", "_config.yml,_config.preview.yml", "--source", directory,
       "--destination", File.join(directory, "_site"), "--trace")
  ruby!(directory, "scripts/check_site.rb", File.join(directory, "_site"))
  Nokogiri::HTML(File.read(File.join(directory, "_site/index.html"), encoding: "UTF-8"))
end

def publication(id, title, year, authors, links = {})
  { "id" => id, "title" => title, "authors" => authors.map(&:dup),
    "venue" => "Temporary Fixture Venue", "year" => year,
    "status" => "published", "links" => links }
end

Dir.mktmpdir("academic-site-regression-") do |directory|
  copy_source(directory)
  config = YAML.safe_load_file(File.join(directory, "_config.yml"), aliases: false)
  config["ready_for_publication"] = false
  config["url"] = ""
  config["baseurl"] = "/fixture-path"
  write_yaml(directory, "_config.yml", config)
  preview = YAML.safe_load_file(File.join(directory, "_config.preview.yml"), aliases: false) || {}
  preview["url"] = ""
  preview["baseurl"] = "/fixture-path"
  write_yaml(directory, "_config.preview.yml", preview)

  profile = {
    "name_en" => "Fixture Person", "name_zh" => "", "position" => "Ph.D. Student",
    "affiliation" => "", "department" => "", "advisor_name" => "", "advisor_url" => "",
    "email_public" => false, "email" => "", "avatar" => "",
    "bio_en" => "Temporary fixture biography: cryptography & <ordinary text>.",
    "bio_zh" => "", "content_confirmed" => false, "research_interests" => [], "links" => {}
  }
  write_yaml(directory, "_data/profile.yml", profile)
  %w[projects news education talks service].each { |name| write_yaml(directory, "_data/#{name}.yml", []) }
  write_yaml(directory, "_data/publications.yml", { "main" => [] })

  empty = build!(directory)
  %w[publications projects news education talks service research research-interests].each do |id|
    assert!(empty.at_css("##{id}").nil?, "Empty optional section #{id} was rendered")
    assert!(empty.css("a[href$='##{id}']").empty?, "Navigation exposes empty optional section #{id}")
  end
  assert!(empty.css("a[href=''], a[href='#']").empty?, "Empty data produced empty links")
  assert!(empty.css("a").none? { |a| a.text.strip == "CV" }, "Missing CV still rendered")
  assert!(empty.at_css("meta[name='robots']")&.[]( "content").to_s.include?("noindex"),
          "Preview lacks noindex")
  puts "PASS: real empty-data Jekyll build, hidden optional sections, no empty links, noindex"

  fixture_file = File.join(directory, "assets/files/fixture paper.html")
  FileUtils.mkdir_p(File.dirname(fixture_file))
  File.write(fixture_file, '<!doctype html><html lang="en"><head><title>Fixture attachment</title></head><body><h1 id="part">Fixture attachment</h1></body></html>', encoding: "UTF-8")
  long_title = "Fixture newest first: " + ("A long scholarly title & careful <text> " * 8) +
               '<script>window.fixtureInjected = true</script>'
  authors = [
    { "name" => "Fixture Person Jr.", "self" => false },
    { "name" => "Fixture Person", "self" => true },
    { "name" => "A & B <C>", "self" => false }
  ] + (1..12).map { |i| { "name" => "Collaborator #{i}", "self" => false } }
  records = [
    publication("fixture-older", "Fixture older publication", 2024, authors),
    publication("fixture-new-first", long_title, 2026, authors,
                { "paper" => "/assets/files/fixture%20paper.html#part", "code" => "", "slides" => "", "bibtex" => "", "doi" => "" }),
    publication("fixture-new-second", "Fixture newest second publication", 2026, authors)
  ]
  write_yaml(directory, "_data/publications.yml", { "main" => records })
  filled = build!(directory)
  text = filled.text
  assert!(text.index(long_title) && text.index("Fixture newest second publication") &&
          text.index("Fixture older publication"), "Publication text was lost or interpreted as HTML")
  assert!(text.index(long_title) < text.index("Fixture newest second publication") &&
          text.index("Fixture newest second publication") < text.index("Fixture older publication"),
          "Publication years or same-year source order are unstable")
  assert!(filled.css("script").none? { |node| node.text.include?("fixtureInjected") },
          "Publication title created executable script content")
  assert!(text.include?("A & B <C>"), "Author text was lost or treated as HTML")
  assert!(filled.css("strong").count { |node| node.text == "Fixture Person" } == 3,
          "Explicit self author was not highlighted once per publication")
  assert!(filled.css("strong").none? { |node| node.text.include?("Fixture Person Jr.") || node.text.include?("A & B <C>") },
          "A non-self author was highlighted")
  assert!(filled.css("a").none? { |a| %w[Code Slides BibTeX DOI].include?(a.text.strip) },
          "Unavailable publication resources created buttons")
  expected_link = "/fixture-path/assets/files/fixture%20paper.html#part"
  assert!(filled.css("a").any? { |a| a["href"] == expected_link && a.text.strip == "Paper" },
          "Encoded local resource/fragment did not receive exactly one baseurl")
  assert!(filled.css("[href], [src]").none? { |node| (node["href"] || node["src"]).include?("/fixture-path/fixture-path/") },
          "A resource has a duplicated baseurl")
  puts "PASS: real three-publication build, year/source ordering, long text, 15 authors, escaping, self markers, optional resources, encoded path/fragment and baseurl"

  index_path = File.join(directory, "_site/index.html")
  original_index = File.read(index_path, encoding: "UTF-8")
  File.write(index_path, original_index.sub("</body>", '<a href="/fixture-path/assets/files/fixture-missing.pdf">Missing fixture file</a></body>'), encoding: "UTF-8")
  ruby!(directory, "scripts/check_site.rb", File.join(directory, "_site"), success: false,
        diagnostic: "fixture-missing.pdf")
  File.write(index_path, original_index.sub("</body>", '<a href="/fixture-path/assets/files/fixture%20paper.html#fixture-missing-fragment">Missing fixture fragment</a></body>'), encoding: "UTF-8")
  ruby!(directory, "scripts/check_site.rb", File.join(directory, "_site"), success: false,
        diagnostic: "fixture-missing-fragment")
  File.write(index_path, original_index, encoding: "UTF-8")
  puts "PASS: generated-site checker rejects a missing file and invalid fragment"

  invalid = Marshal.load(Marshal.dump(records))
  invalid[2]["id"] = invalid[1]["id"]
  write_yaml(directory, "_data/publications.yml", { "main" => invalid })
  ruby!(directory, "scripts/validate_content.rb", "--mode", "preview", success: false, diagnostic: "id")
  invalid = Marshal.load(Marshal.dump(records))
  invalid[0]["year"] = 0
  write_yaml(directory, "_data/publications.yml", { "main" => invalid })
  ruby!(directory, "scripts/validate_content.rb", "--mode", "preview", success: false, diagnostic: "year")
  invalid = Marshal.load(Marshal.dump(records))
  invalid[0].delete("title")
  write_yaml(directory, "_data/publications.yml", { "main" => invalid })
  ruby!(directory, "scripts/validate_content.rb", "--mode", "preview", success: false, diagnostic: "title")
  write_yaml(directory, "_data/publications.yml", { "main" => records })
  ruby!(directory, "scripts/validate_content.rb", "--mode", "production", success: false,
        diagnostic: "ready_for_publication")
  puts "PASS: validator rejects duplicate IDs, invalid year, missing required field and unapproved production content"

  # The boolean alone must not bypass the separate identity/content/address
  # checks. These intentionally incomplete records live only in this fixture.
  config["ready_for_publication"] = true
  config["preview_mode"] = false
  config["github_username"] = ""
  config["url"] = ""
  config["baseurl"] = ""
  write_yaml(directory, "_config.yml", config)
  incomplete_profile = profile.merge("name_en" => "", "bio_en" => "", "content_confirmed" => false)
  write_yaml(directory, "_data/profile.yml", incomplete_profile)
  refusal = ruby!(directory, "scripts/validate_content.rb", "--mode", "production", success: false)
  %w[content_confirmed name_en bio_en url].each do |field|
    assert!(refusal.include?(field), "Ready-only production gate missed #{field}:\n#{refusal}")
  end
  assert!(refusal.include?("GitHub username"), "Ready-only production gate missed username:\n#{refusal}")
  assert!(!refusal.include?("ready_for_publication is false"), "Ready-only fixture did not actually enable its boolean")
  puts "PASS: ready_for_publication=true alone cannot bypass confirmed content, name, biography, username or site URL"

  # A positive production render is still wholly synthetic and local. Never
  # write these details to formal data or upload this temporary output.
  config["github_username"] = "fixture-person"
  config["url"] = "https://fixture-person.github.io"
  write_yaml(directory, "_config.yml", config)
  write_yaml(directory, "_data/profile.yml", profile.merge("content_confirmed" => true))
  production_environment = { "JEKYLL_ENV" => "production" }
  ruby!(directory, "scripts/validate_content.rb", "--mode", "production", environment: production_environment)
  run!(directory, RbConfig.ruby, Gem.bin_path("jekyll", "jekyll"), "build",
       "--config", "_config.yml", "--source", directory,
       "--destination", File.join(directory, "_site"), "--trace", environment: production_environment)
  ruby!(directory, "scripts/check_site.rb", File.join(directory, "_site"), environment: production_environment)
  production = Nokogiri::HTML(File.read(index_path, encoding: "UTF-8"))
  expected_origin = "https://fixture-person.github.io"
  assert!(production.at_css("link[rel='canonical']")&.[]( "href") == "#{expected_origin}/",
          "Production canonical does not match the confirmed fixture site URL")
  assert!(production.css("meta[name='robots']").none? { |meta| meta["content"].to_s.include?("noindex") },
          "Production kept preview noindex metadata")
  assert!(production.at_css(".preview-notice").nil?, "Production kept the preview notice")
  sitemap = Nokogiri::XML(File.read(File.join(directory, "_site/sitemap.xml"), encoding: "UTF-8")) { |xml| xml.strict }
  assert!(sitemap.xpath("//*[local-name()='loc']").map(&:text) == ["#{expected_origin}/"],
          "Production sitemap does not match canonical URL")
  robots = File.read(File.join(directory, "_site/robots.txt"), encoding: "UTF-8")
  assert!(robots.include?("Sitemap: #{expected_origin}/sitemap.xml") && !robots.include?("Disallow: /"),
          "Production robots.txt kept preview rules or a wrong sitemap address")
  puts "PASS: real JEKYLL_ENV=production build and checker, canonical/sitemap/robots agree, no preview notice or noindex"

  # BibTeX is generated from the same publication data as the visible page.
  # Verify that a metadata edit is detected before publishing stale citations.
  citation_record = publication("fixture-bibtex", "Fixture citation original title", 2026,
                                [{ "name" => "Fixture Person", "self" => true }],
                                { "bibtex" => "/assets/files/fixture.bib" })
  citation_record["citation"] = { "volume" => "42", "number" => "7", "pages" => "1--9" }
  write_yaml(directory, "_data/publications.yml", { "main" => [citation_record] })
  ruby!(directory, "scripts/generate_bibtex.rb")
  ruby!(directory, "scripts/generate_bibtex.rb", "--check")
  citation_path = File.join(directory, "assets/files/fixture.bib")
  generated_citation = File.read(citation_path, encoding: "UTF-8")
  assert!(generated_citation.include?(citation_record["title"]) && generated_citation.include?("Fixture Person"),
          "Generated BibTeX did not reflect canonical publication metadata")
  citation_record["title"] = "Fixture citation revised title"
  write_yaml(directory, "_data/publications.yml", { "main" => [citation_record] })
  ruby!(directory, "scripts/generate_bibtex.rb", "--check", success: false, diagnostic: "fixture.bib")
  assert!(File.read(citation_path, encoding: "UTF-8") == generated_citation,
          "BibTeX --check modified a stale file")
  ruby!(directory, "scripts/generate_bibtex.rb")
  ruby!(directory, "scripts/generate_bibtex.rb", "--check")
  assert!(File.read(citation_path, encoding: "UTF-8").include?(citation_record["title"]),
          "Regenerating BibTeX did not apply updated metadata")
  puts "PASS: BibTeX generation uses canonical data, --check rejects stale citations without writing, regeneration updates metadata"
end

puts "All temporary-fixture regression checks passed; formal data and output were untouched."
