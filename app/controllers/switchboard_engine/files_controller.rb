module SwitchboardEngine
  class FilesController < ApplicationController
    # GET /files
    def index
      # Get distinct filenames from speakers table
      filenames = Speaker.distinct.pluck(:filename).compact.sort

      respond_to do |format|
        format.html
        format.json do
          render json: { files: filenames.map { |f| { filename: f } } }
        end
      end
    end

    # GET /files/:filename
    def show
      filename = params[:filename]

      # Get all speakers for this file
      speakers = Speaker.where(filename: filename)

      # Get all segments for this file
      segments = Segment.where(filename: filename).order(:beg)

      respond_to do |format|
        format.html
        format.json do
          render json: {
            filename: filename,
            speakers: speakers,
            segments: segments
          }
        end
      end
    end
  end
end
