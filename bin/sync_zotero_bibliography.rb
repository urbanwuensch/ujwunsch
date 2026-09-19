# -*- coding: utf-8 -*-
# frozen_string_literal: true

# Refreshes _bibliography/papers.bib from the Zotero "My Publications" library.
# Run with: bundle exec ruby bin/sync_zotero_bibliography.rb
#
# Zotero user ID and "My Publications" curation are the source of truth: whatever
# is added to https://www.zotero.org/urbanwunsch/ (My Publications) shows up here.
# Zotero-internal fields that would leak local file paths or add noise are dropped.

require "net/http"
require "uri"
require "bibtex"

ZOTERO_USER_ID = "7336663"
BIBLIOGRAPHY_PATH = File.join(__dir__, "..", "_bibliography", "papers.bib")
STRIPPED_FIELDS = %i[file note langid shortjournal copyright month_numeric].freeze

def fetch_bibtex(user_id)
  uri = URI("https://api.zotero.org/users/#{user_id}/publications/items?format=bibtex&limit=100")
  response = Net::HTTP.get_response(uri)
  raise "Zotero API request failed: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

  response.body
end

def clean(bibtex_text)
  bib = BibTeX.parse(bibtex_text)
  bib.each do |entry|
    STRIPPED_FIELDS.each { |field| entry.delete(field) }

    # Enables the Dimensions.ai "times cited" badge on /publications/ and the
    # CV: the al_folio_core bib layout resolves it from the entry's DOI, no
    # separate ID needed. See site.enable_publication_badges in _config.yml.
    entry.add(:dimensions, "true") if entry[:doi]
  end
  bib
end

raw = fetch_bibtex(ZOTERO_USER_ID)
bib = clean(raw)

if bib.empty?
  warn "Zotero returned no publications; leaving #{BIBLIOGRAPHY_PATH} untouched."
  exit 1
end

File.write(BIBLIOGRAPHY_PATH, bib.to_s)
puts "Synced #{bib.length} entries from Zotero My Publications into #{BIBLIOGRAPHY_PATH}"
