// Links the Ops admin pages from Zammad's admin menu, in its Ops section, opening in a new tab. hacks/hacks.rb loads it
// right after application.js.
(function () {
  'use strict';

  if (!window.App || !App.ControllerSubContent) return;

  var PAGES = ['/ops/owner_handovers'];

  // a section of its own, after System (prio 8000); admin only, so agents with an admin.* permission see no empty one
  App.Config.set('Ops', { prio: 9000, name: 'Ops', target: '#ops', permission: ['admin'] }, 'NavBarAdmin');

  App.Config.set('OpsOwnerHandover', {
    prio: 1000,
    name: 'Handover',
    parent: '#ops',
    target: PAGES[0],
    // the menu lists only items with a controller; never run, the link leaves the app
    controller: class extends App.ControllerSubContent {},
    permission: ['admin'],
  }, 'NavBarAdmin');

  // the menu renders a plain link, which would leave the app in this tab; the menu is redrawn often, so this marks the
  // link when it is clicked (before the browser follows it), which keeps ctrl/cmd and middle clicks working as well
  document.addEventListener('click', function (event) {
    var link = event.target.closest && event.target.closest('a[href]');
    if (!link || PAGES.indexOf(link.getAttribute('href')) === -1) return;

    link.target = '_blank';
    link.rel = 'noopener';
  }, true);

  // application.js starts the app as it loads, so on a reload of an admin page the menu may have rendered before this
  // script ran: redraw its sidebar.
  var manage = App.TaskManager && App.TaskManager.worker('Manage');
  if (!manage) return;

  var groups = manage.groupsSorted();
  manage.$('.sidebar').html(App.view('generic/navbar_level2/navbar')({
    groups: groups,
    className: manage.configKey,
    selectedItem: manage.selectedItem(groups),
  }));
})();
