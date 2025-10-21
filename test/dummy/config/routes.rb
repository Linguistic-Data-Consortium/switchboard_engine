Rails.application.routes.draw do
  # This route will be provided by the host app in production
  get 'switchboard', to: 'switchboard#show'

  get 'files', to: 'files#index'
  get 'files/:filename', to: 'files#show', as: 'file', constraints: { filename: /[^\/]+/ }

  resources :segments do
    post :upload, on: :collection
    delete :delete_all, on: :collection
  end
  resources :speakers do
    post :upload, on: :collection
    delete :delete_all, on: :collection
  end
  mount SwitchboardEngine::Engine => "/switchboard_engine"
end
