Rails.application.routes.draw do
  mount SwitchboardEngine::Engine => "/swb"
end
