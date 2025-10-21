class SwitchboardController < ApplicationController
  # This controller serves audio files
  # In production, the host app will implement this route to serve actual audio files
  # For the dummy app, we serve the same dummy.mp3 file for all requests
  def show
    filename = params[:filename]
    audio_path = Rails.root.join('public', 'audio', 'dummy.mp3')

    if File.exist?(audio_path)
      send_file audio_path, type: 'audio/mpeg', disposition: 'inline'
    else
      head :not_found
    end
  end
end
