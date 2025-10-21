class FilesController < ApplicationController
  # GET /files
  def index
    # Get distinct filenames from speakers table
    filenames = Speaker.distinct.pluck(:filename).compact.sort

    render inertia: "files_index", props: {
      files: filenames.map { |f| { filename: f } }
    }
  end

  # GET /files/:filename
  def show
    filename = params[:filename]

    # Get all speakers for this file
    speakers = Speaker.where(filename: filename).as_json

    # Get all segments for this file
    segments = Segment.where(filename: filename).order(:beg).as_json

    render inertia: "files_show", props: {
      filename: filename,
      speakers: speakers,
      segments: segments
    }
  end
end
