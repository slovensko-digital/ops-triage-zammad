// Agent autocomplete for the Ops admin pages (/ops/...), like the owner field of the Trigger UI: searches the agents
// through Zammad's /api/v1/users/search as the logged in admin and puts the picked agent's email in the hidden input.
//
//   <span class="user-autocomplete">
//     <input type="text" class="user-autocomplete-query">
//     <input type="hidden" name="new_email">
//     <ul class="user-autocomplete-results" hidden></ul>
//   </span>
(function () {
  'use strict';

  var LIMIT = 20;
  var DELAY = 200;

  // the page's language, <html lang> of layouts/ops.html.erb
  var TEXTS = {
    en: { none: 'No owner found', inactive: ' (inactive)', pick: 'Pick an owner from the list' },
    sk: { none: 'Žiaden vlastník sa nenašiel', inactive: ' (neaktívny)', pick: 'Vyberte vlastníka zo zoznamu' },
  };
  var TEXT = TEXTS[document.documentElement.lang] || TEXTS.en;

  function fullName(user) {
    return [user.firstname, user.lastname].filter(Boolean).join(' ') || user.login;
  }

  function label(user) {
    return fullName(user) + ' <' + user.email + '>';
  }

  function setup(root) {
    var query = root.querySelector('.user-autocomplete-query');
    var value = root.querySelector('input[type=hidden]');
    var list = root.querySelector('.user-autocomplete-results');
    var users = [];
    var active = -1;
    var timer = null;
    var request = 0;

    function close() {
      list.hidden = true;
      active = -1;
    }

    function highlight(index) {
      var items = list.querySelectorAll('li[data-index]');
      if (!items.length) return;
      active = (index + items.length) % items.length;
      items.forEach(function (item, i) { item.classList.toggle('active', i === active); });
      items[active].scrollIntoView({ block: 'nearest' });
    }

    function pick(user) {
      value.value = user.email;
      query.value = label(user);
      query.setCustomValidity('');
      close();
    }

    function render() {
      list.innerHTML = '';
      if (!users.length) {
        var empty = document.createElement('li');
        empty.className = 'empty';
        empty.textContent = TEXT.none;
        list.appendChild(empty);
      }
      users.forEach(function (user, index) {
        var item = document.createElement('li');
        item.dataset.index = index;
        var name = document.createElement('span');
        name.className = 'name';
        name.textContent = fullName(user) + (user.active ? '' : TEXT.inactive);
        var email = document.createElement('span');
        email.className = 'email';
        email.textContent = user.email;
        item.appendChild(name);
        item.appendChild(email);
        // mousedown, the blur closing the list comes before click
        item.addEventListener('mousedown', function (event) {
          event.preventDefault();
          pick(user);
        });
        list.appendChild(item);
      });
      list.hidden = false;
      active = -1;
    }

    function search(term) {
      var current = ++request;
      var url = '/api/v1/users/search?expand=true&limit=' + LIMIT +
        '&permissions%5B%5D=ticket.agent&query=' + encodeURIComponent(term);
      fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } })
        .then(function (response) { return response.ok ? response.json() : []; })
        .then(function (result) {
          if (current !== request) return;
          users = (Array.isArray(result) ? result : []).filter(function (user) { return user.email; });
          render();
        })
        .catch(function () { if (current === request) { users = []; render(); } });
    }

    query.addEventListener('input', function () {
      // typed over the picked agent: an email typed in full still counts, anything else has to be picked
      var typed = query.value.trim();
      value.value = /^[^\s<>@]+@[^\s<>@]+$/.test(typed) ? typed : '';
      clearTimeout(timer);
      if (!typed) { close(); return; }
      timer = setTimeout(function () { search(typed); }, DELAY);
    });

    query.addEventListener('keydown', function (event) {
      if (list.hidden) return;
      if (event.key === 'ArrowDown') { event.preventDefault(); highlight(active + 1); }
      else if (event.key === 'ArrowUp') { event.preventDefault(); highlight(active - 1); }
      else if (event.key === 'Escape') { close(); }
      else if (event.key === 'Enter' && active >= 0) { event.preventDefault(); pick(users[active]); }
    });

    query.addEventListener('focus', function () { if (users.length && query.value.trim() && !value.value) list.hidden = false; });
    query.addEventListener('blur', close);

    // the browser validates the visible field, the hidden one carries the value
    if (query.required && query.form) {
      query.form.addEventListener('submit', function (event) {
        if (value.value) return;
        query.setCustomValidity(TEXT.pick);
        query.reportValidity();
        event.preventDefault();
      });
      query.addEventListener('input', function () { query.setCustomValidity(''); });
    }
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.user-autocomplete').forEach(setup);
  });
})();
