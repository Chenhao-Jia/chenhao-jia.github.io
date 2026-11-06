source "https://rubygems.org"

ruby "~> 3.3.0"

gem "jekyll", "~> 4.4.1"
gem "webrick", "~> 1.9"
gem "nokogiri", "~> 1.18"

# Windows does not ship the IANA timezone database.
platforms :windows, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end
