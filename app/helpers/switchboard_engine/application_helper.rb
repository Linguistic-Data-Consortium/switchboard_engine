module SwitchboardEngine
  module ApplicationHelper
    # Override: Returns the engine assets manifest.
    def vite_manifest
      SwitchboardEngine::Engine.vite_ruby.manifest
    end
  end
end
