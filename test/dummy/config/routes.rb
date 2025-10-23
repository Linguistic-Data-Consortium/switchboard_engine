Rails.application.routes.draw do
  # This route will be provided by the host app in production
  get 'switchboard', to: 'switchboard#show'
  mount SwitchboardEngine::Engine => "/swb"
end
