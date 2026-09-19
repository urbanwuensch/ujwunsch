module.exports = {
  content: ["_site/**/*.html", "_site/**/*.js"],
  css: ["_site/assets/css/*.css"],
  output: "_site/assets/css/",
  skippedContentGlobs: ["_site/assets/**/*.html"],
  safelist: {
    standard: [
      "collapse",
      "collapsing",
      "show",
      "dropdown-menu",
      "dropdown-item",
      "table",
      "table-dark",
      "table-hover",
      "table-responsive",
      "af-tooltip",
      "af-popover",
      "font-weight-bold",
      "font-weight-medium",
      "font-weight-lighter",
      // medium-zoom injects these at runtime, so they never appear in the static
      // HTML PurgeCSS scans; without them the zoom overlay's z-index rule is purged
      // and page chrome (scroll-progress bar, ToC) bleeds through a zoomed image.
      "medium-zoom-overlay",
      "medium-zoom-image--opened",
      // common.js toggles this onto .abstract/.award/.bibtex.hidden panels on
      // click (Abs/Award/Bib buttons on /publications/); without it the panel's
      // reveal rule (div.abstract.hidden.open, etc.) is purged, so clicking the
      // button does nothing visible even though the class toggle itself works.
      "open",
    ],
    // PurgeCSS's default (standard) matching drops selectors built from
    // attribute selectors like a.nav-link[href$="/cv/"] even though the
    // plain class (.nav-link) is used all over the site - "standard" string
    // matches don't reliably keep those, "deep" (regex against the full
    // selector) does. See _sass/_components.scss's nav-link lowercase rule.
    deep: [/nav-link/],
  },
};
