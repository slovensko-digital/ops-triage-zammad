# Ops admin pages, rendered by Rails next to the Zammad app, for admins logged in to Triage.
#
#   GET  /ops/owner_handovers                  owner_handovers#index, ?owner_id= of the owner leaving redirects to show
#   GET  /ops/owner_handovers/mismatches       owner_handovers#mismatches
#   GET  /ops/owner_handovers/:id              owner_handovers#show, the handover of the owner (user id) leaving
#   POST /ops/owner_handovers/:id/preview      owner_handovers#preview
#   GET  /ops/owner_handovers/runs             owner_handover_runs#index
#   POST /ops/owner_handovers/runs             owner_handover_runs#create
#   GET  /ops/owner_handovers/runs/statuses    owner_handover_runs#statuses
#   GET  /ops/owner_handovers/runs/:id         owner_handover_runs#show
Zammad::Application.routes.draw do
  namespace :ops do
    # before owner_handovers, whose /:id would take runs
    resources :owner_handover_runs, path: 'owner_handovers/runs', only: %i[index show create] do
      get :statuses, on: :collection
    end
    resources :owner_handovers, only: %i[index show] do
      get :mismatches, on: :collection
      post :preview, on: :member
    end
  end
end
