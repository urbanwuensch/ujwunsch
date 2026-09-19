# -*- coding: utf-8 -*-
# frozen_string_literal: true

# Refreshes _bibliography/papers.bib from the Zotero "My Publications" library.
# Run with: bundle exec ruby bin/sync_zotero_bibliography.rb
#
# Zotero user ID and "My Publications" curation are the source of truth: whatever
# is added to https://www.zotero.org/urbanwunsch/ (My Publications) shows up here.
# Zotero-internal fields that would leak local file paths or add noise are dropped.
#
# Citation counts come from OpenAlex (free, no API key, matched by DOI) and are
# baked in as a static `citations` field rather than using a third-party badge
# widget (Dimensions/Altmetric): those get silently blocked by ad blockers and
# privacy-focused browsers (confirmed blocked in Zen, for one), so a live embed
# just doesn't render for a meaningful share of visitors. A plain number in the
# built HTML has nothing for a blocker to catch.

require "net/http"
require "uri"
require "json"
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

def normalize_doi(doi)
  doi.to_s.sub(%r{\Ahttps?://(dx\.)?doi\.org/}i, "").strip.downcase
end

def normalize_title(title)
  title.to_s.downcase.gsub(/[^a-z0-9]+/, " ").strip
end

# Falls back to an OpenAlex title search when the DOI lookup finds nothing -
# e.g. Zotero sometimes exports a shortDOI (10/xxxxx) instead of the real DOI,
# which OpenAlex's exact `filter=doi:` match won't resolve. Title search can
# return several near-duplicate records for one paper (the article itself,
# a conference abstract, a data deposit, ...), so this only accepts a result
# whose title matches exactly (once normalized) AND whose author list
# includes Wünsch - anything less certain is left unset rather than risk
# attaching the wrong count. No manual review needed: it either finds a
# confident match or silently skips, same as a DOI that simply isn't indexed.
def title_search_citation_count(title)
  return nil if title.to_s.strip.empty?

  # bibtex-ruby preserves LaTeX case-protection braces (e.g. "{DOM}", "{Earth}")
  # verbatim; sending those literal '{' '}' characters to OpenAlex's search
  # breaks the match, so strip them for the query (normalize_title already
  # strips them for the exact-match comparison below).
  query = URI.encode_www_form_component(title.delete("{}"))
  uri = URI("https://api.openalex.org/works?filter=title.search:#{query}&select=title,cited_by_count,authorships&per-page=5")
  response = Net::HTTP.get_response(uri)
  return nil unless response.is_a?(Net::HTTPSuccess)

  target = normalize_title(title)
  JSON.parse(response.body)["results"].each do |work|
    next unless normalize_title(work["title"]) == target
    next unless work["authorships"].to_a.any? { |a| a.dig("author", "display_name").to_s.include?("Wünsch") }

    return work["cited_by_count"]
  end
  nil
rescue StandardError => e
  warn "Title-search fallback failed for #{title.inspect}: #{e.message}"
  nil
end

# OpenAlex works?filter=doi:a|b|c supports batched OR lookups; slice defensively
# in case the bibliography grows well past what fits comfortably in one request.
def fetch_citation_counts(dois)
  counts = {}
  dois.uniq.each_slice(50) do |batch|
    filter_value = batch.map { |doi| URI.encode_www_form_component(doi) }.join("|")
    uri = URI("https://api.openalex.org/works?filter=doi:#{filter_value}&select=doi,cited_by_count&per-page=100")
    response = Net::HTTP.get_response(uri)
    unless response.is_a?(Net::HTTPSuccess)
      warn "OpenAlex citation lookup failed: #{response.code} #{response.message}"
      next
    end

    JSON.parse(response.body)["results"].each do |work|
      counts[normalize_doi(work["doi"])] = work["cited_by_count"]
    end
  end
  counts
end

def clean(bibtex_text)
  bib = BibTeX.parse(bibtex_text)
  bib.each { |entry| STRIPPED_FIELDS.each { |field| entry.delete(field) } }
  bib
end

def apply_citation_counts(bib)
  dois = bib.filter_map { |entry| entry[:doi] && normalize_doi(entry[:doi].to_s) }
  counts = fetch_citation_counts(dois)
  bib.each do |entry|
    count = entry[:doi] && counts[normalize_doi(entry[:doi].to_s)]
    count ||= title_search_citation_count(entry[:title]&.to_s)
    entry.add(:citations, count.to_s) if count
  end
end

raw = fetch_bibtex(ZOTERO_USER_ID)
bib = clean(raw)

if bib.empty?
  warn "Zotero returned no publications; leaving #{BIBLIOGRAPHY_PATH} untouched."
  exit 1
end

apply_citation_counts(bib)

File.write(BIBLIOGRAPHY_PATH, bib.to_s)
puts "Synced #{bib.length} entries from Zotero My Publications into #{BIBLIOGRAPHY_PATH}"
