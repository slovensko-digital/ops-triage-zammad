// Adds the Ops admin pages (/ops/..., rendered by Rails) to Zammad's admin menu, under System, for admins only, as the
// server allows them. hacks/hacks.rb loads it into the app layout right after application.js, which has started the app
// by then; the admin menu reads NavBarAdmin when it renders (redrawn below if it already has) and the existing
// system/:target route opens the item.
(function () {
  'use strict';

  if (!window.App || !App.ControllerSubContent) return;

  function embeddedPage(header, src) {
    return class extends App.ControllerSubContent {
      static requiredPermission = 'admin';

      constructor(params) {
        super(params);
        this.header = header;
        this.html(
          '<iframe class="ops-admin-frame" src="' + src + '" title="' + header + '" ' +
          'style="display: block; width: 100%; height: 100vh; border: 0;"></iframe>'
        );
      }
    };
  }

  App.Config.set('OpsOwnerHandover', {
    prio: 3800,
    name: 'Owner handover',
    parent: '#system',
    target: '#system/ops_owner_handover',
    controller: embeddedPage('Owner handover', '/ops/owner_handover'),
    permission: ['admin'],
  }, 'NavBarAdmin');

  // application.js starts the app as it loads, so on a reload of an admin page the menu may have rendered before this
  // script ran: redraw its sidebar, and open the page if the URL points at it (Zammad fell back to the first item).
  var manage = App.TaskManager && App.TaskManager.worker('Manage');
  if (!manage) return;

  var groups = manage.groupsSorted();
  manage.$('.sidebar').html(App.view('generic/navbar_level2/navbar')({
    groups: groups,
    className: manage.configKey,
    selectedItem: manage.selectedItem(groups),
  }));
  var lastTarget = manage.lastTarget;
  manage.updateNavigation(false, {});
  if (manage.shown && manage.lastTarget !== lastTarget) manage.activeController.show();
})();
