SwitchboardEngine::Engine.routes.draw do
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
end
