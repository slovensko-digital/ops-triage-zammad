# Ops admin pages, rendered by Rails next to the Zammad app, for admins logged in to Triage.
Zammad::Application.routes.draw do
  handover = 'ops/owner_handovers'
  get '/ops/owner_handover', to: "#{handover}#index", as: :ops_owner_handover
  get '/ops/owner_handover/conflicts', to: "#{handover}#conflicts", as: :ops_owner_handover_conflicts
  get '/ops/owner_handover/report', to: "#{handover}#report", as: :ops_owner_handover_report
  post '/ops/owner_handover/preview', to: "#{handover}#preview", as: :ops_owner_handover_preview
  get '/ops/owner_handover/runs', to: "#{handover}#runs", as: :ops_owner_handover_runs
  post '/ops/owner_handover/runs', to: "#{handover}#create_run"
  get '/ops/owner_handover/runs/:id', to: "#{handover}#show_run", as: :ops_owner_handover_run
end
