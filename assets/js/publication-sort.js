// Toggle between al-folio's default year-grouped bibliography and a flat
// list sorted by citation count. Citation counts come from the `data-citations`
// attribute bin/sync_zotero_bibliography.rb + _layouts/bib.liquid put on each
// entry's .row div (see _bibliography/papers.bib and _layouts/bib.liquid).
document.addEventListener("DOMContentLoaded", function () {
  const container = document.querySelector(".publications");
  const bibsearch = document.getElementById("bibsearch");
  if (!container) return;

  const pristineHTML = container.innerHTML;

  const setActive = (sortByYearBtn, sortByCitationsBtn, mode) => {
    sortByYearBtn.classList.toggle("active", mode === "year");
    sortByCitationsBtn.classList.toggle("active", mode === "citations");
  };

  const sortByCitations = () => {
    const entries = Array.from(container.querySelectorAll("ol.bibliography > li"));
    entries.sort((a, b) => {
      const aCount = Number(a.querySelector(".row")?.dataset.citations || 0);
      const bCount = Number(b.querySelector(".row")?.dataset.citations || 0);
      return bCount - aCount;
    });

    const firstList = container.querySelector("ol.bibliography");
    if (!firstList) return;

    // Drop the year headers and collapse every year's <ol> into the first one.
    container.querySelectorAll("h2.bibliography").forEach((el) => el.remove());
    container.querySelectorAll("ol.bibliography").forEach((ol) => {
      if (ol !== firstList) ol.remove();
    });
    entries.forEach((li) => firstList.appendChild(li));
  };

  const restoreYearOrder = () => {
    container.innerHTML = pristineHTML;
  };

  const toolbar = document.createElement("div");
  toolbar.className = "publication-sort-toolbar";
  toolbar.style.margin = "0.5rem 0 1rem";

  const yearBtn = document.createElement("button");
  yearBtn.type = "button";
  yearBtn.className = "btn btn-sm z-depth-0 active";
  yearBtn.textContent = "Sort: Year";

  const citationsBtn = document.createElement("button");
  citationsBtn.type = "button";
  citationsBtn.className = "btn btn-sm z-depth-0";
  citationsBtn.style.marginLeft = "0.5rem";
  citationsBtn.textContent = "Sort: Citations";

  yearBtn.addEventListener("click", () => {
    restoreYearOrder();
    setActive(yearBtn, citationsBtn, "year");
    if (bibsearch) bibsearch.value = "";
  });

  citationsBtn.addEventListener("click", () => {
    // Start from a clean, fully-grouped copy so re-sorting after a filter
    // (or after switching back to year order) always sees every entry.
    restoreYearOrder();
    sortByCitations();
    setActive(yearBtn, citationsBtn, "citations");
    if (bibsearch) bibsearch.value = "";
  });

  toolbar.appendChild(yearBtn);
  toolbar.appendChild(citationsBtn);
  container.parentElement.insertBefore(toolbar, container);
});
