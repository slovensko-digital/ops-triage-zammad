// Follows the queued and running owner handover runs listed on an Ops page (cells with data-run-id) and updates their
// status. When one ends, the page reloads, unless a new owner has been picked on it: then #runs-finished asks to reload.
(function () {
  'use strict';

  var EVERY = 3000;
  var ACTIVE = ['queued', 'running'];
  // the statuses as config/locales/ops.*.yml names them, by <html lang>
  var STATUSES = {
    en: { queued: 'queued', running: 'running', done: 'done', failed: 'failed' },
    sk: { queued: 'v poradí', running: 'beží', done: 'hotovo', failed: 'zlyhalo' },
  };
  var STATUS = STATUSES[document.documentElement.lang] || STATUSES.en;

  function picked() {
    return Array.prototype.some.call(document.querySelectorAll('.user-autocomplete input[type=hidden]'), function (input) {
      return input.value;
    });
  }

  function poll(cells) {
    var url = '/ops/owner_handover/runs/statuses?' + cells.map(function (cell) {
      return 'ids%5B%5D=' + encodeURIComponent(cell.dataset.runId);
    }).join('&');

    fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } })
      .then(function (response) { return response.ok ? response.json() : {}; })
      .then(function (statuses) {
        var ended = false;
        cells = cells.filter(function (cell) {
          var status = statuses[cell.dataset.runId];
          if (!status) return true;
          cell.textContent = STATUS[status] || status;
          cell.className = 'status-' + status;
          if (ACTIVE.indexOf(status) !== -1) return true;
          ended = true;
          return false;
        });
        if (ended) {
          if (!picked()) { window.location.reload(); return; }
          var notice = document.getElementById('runs-finished');
          if (notice) notice.hidden = false;
        }
        if (cells.length) setTimeout(function () { poll(cells); }, EVERY);
      })
      .catch(function () { setTimeout(function () { poll(cells); }, EVERY); });
  }

  document.addEventListener('DOMContentLoaded', function () {
    var cells = Array.prototype.slice.call(document.querySelectorAll('[data-run-id]'));
    if (cells.length) setTimeout(function () { poll(cells); }, EVERY);
  });
})();
