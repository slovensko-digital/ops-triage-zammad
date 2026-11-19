# Ops admin pages, rendered by Rails next to the Zammad app, for admins logged in to Triage.
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
