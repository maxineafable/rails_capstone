// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

let savedScrollPosition = 0;

document.addEventListener("click", (event) => {
  const link = event.target.closest('a[data-preserve-scroll="true"]');

  if (link) {
    savedScrollPosition = window.scrollY;
  }
});

document.addEventListener("turbo:load", () => {
  window.scrollTo(0, savedScrollPosition);
});