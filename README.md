# ujwunsch.com

Personal/academic website of Urban Wünsch, built on [al-folio](https://github.com/alshedivat/al-folio) (Jekyll).

## Local development

```bash
bundle install
bundle exec jekyll serve
```

Site is served at `http://localhost:4000/`.

## Content

- `_pages/about.md` — homepage bio
- `assets/json/resume.json` — canonical CV data (JSON Resume format, with local `teaching`/`supervision`/`conferences` extensions); drives both the `/cv/` page and the downloadable PDF (see below)
- `_bibliography/papers.bib` — publications, synced from [Zotero My Publications](https://www.zotero.org/urbanwunsch) by `bin/sync_zotero_bibliography.rb` (runs weekly via `.github/workflows/sync-zotero.yml`, opens a PR — review before merging)
- `_projects/` — project cards for the `/projects/` page

## Regenerating the CV PDF

The PDF is built from `assets/json/resume.json` via a locally patched fork of [jsoncv](https://github.com/reorx/jsoncv) (adds the `teaching`/`supervision`/`conferences` sections al-folio's own CV layout also renders — see `_includes/cv/render.liquid`):

```bash
cd <path-to-jsoncv-fork>
DATA_FILENAME=<path-to-this-repo>/assets/json/resume.json npm run build
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --print-to-pdf=Urban_Wunsch_CV.pdf --print-to-pdf-no-header \
  file://<path-to-jsoncv-fork>/dist/index.html
cp Urban_Wunsch_CV.pdf assets/pdf/CV_Wuensch.pdf
```

## Deployment

GitHub Actions (`.github/workflows/deploy.yml`) builds the site and publishes to the `gh-pages` branch on every push to `main`.

## Local overrides of the al-folio theme

This site shadows a few theme-gem files locally (standard, documented al-folio v1.x practice — local files win over the gem's):

- `_sass/_variables.scss`, `_sass/_themes.scss` — accent color (black instead of al-folio's default purple)
- `_sass/_components.scss` — smaller footer social icons
- `_includes/cv/render.liquid` — adds Teaching/Supervision/Conferences sections to the CV page
