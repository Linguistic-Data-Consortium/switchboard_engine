class SegmentsController < ApplicationController
  before_action :set_segment, only: %i[ show edit update destroy ]

  # GET /segments
  def index
    render inertia: "segments_index", props: {
      segments: Segment.limit(1000).as_json
    }
  end

  # GET /segments/1
  def show
  end

  # GET /segments/new
  def new
    @segment = Segment.new
  end

  # GET /segments/1/edit
  def edit
  end

  # POST /segments
  def create
    @segment = Segment.new(segment_params)

    if @segment.save
      redirect_to @segment, notice: "Segment was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /segments/1
  def update
    if @segment.update(segment_params)
      redirect_to @segment, notice: "Segment was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /segments/1
  def destroy
    @segment.destroy!
    redirect_to segments_path, notice: "Segment was successfully destroyed.", status: :see_other
  end

  # POST /segments/upload
  def upload
    Rails.logger.info "=== SEGMENTS UPLOAD DEBUG START ==="
    Rails.logger.info "File present? #{params[:file].present?}"

    unless params[:file].present?
      Rails.logger.info "No file in params"
      redirect_to segments_path, alert: "No file uploaded."
      return
    end

    uploaded_file = params[:file]
    temp_path = Rails.root.join("tmp", "upload_#{SecureRandom.hex}.sqlite3")
    Rails.logger.info "Temp path: #{temp_path}"

    begin
      # Save uploaded file
      File.open(temp_path, "wb") { |f| f.write(uploaded_file.read) }
      Rails.logger.info "File saved, size: #{File.size(temp_path)} bytes"

      # Connect to uploaded SQLite database
      uploaded_db = SQLite3::Database.new(temp_path.to_s)
      uploaded_db.results_as_hash = true
      Rails.logger.info "Database opened"

      # Check tables
      tables = uploaded_db.execute("SELECT name FROM sqlite_master WHERE type='table'")
      Rails.logger.info "Tables in database: #{tables.inspect}"

      # Determine which table to use (segments or ldc97s62)
      table_name = if tables.any? { |t| t["name"] == "segments" }
        "segments"
      elsif tables.any? { |t| t["name"] == "ldc97s62" }
        "ldc97s62"
      else
        raise "No 'segments' or 'ldc97s62' table found in database"
      end

      Rails.logger.info "Using table: #{table_name}"

      # Query from uploaded database with optional limit
      limit = params[:limit].to_i if params[:limit].present?
      query = "SELECT * FROM #{table_name}"
      query += " LIMIT #{limit}" if limit && limit > 0

      rows = uploaded_db.execute(query)
      Rails.logger.info "Found #{rows.length} rows"

      imported_count = 0
      rows.each_with_index do |row, idx|
        Rails.logger.info "Row #{idx}: #{row.inspect}" if idx < 3  # Log first 3 rows

        # Map fields from source to target
        # ldc97s62 table mapping:
        # doc_id -> filename, speaker -> channel, segment -> text
        # starts -> beg, ends -> end, id -> id, turn -> turn
        filename = row["doc_id"] || row["filename"]
        channel = row["speaker"] || row["channel"]
        text = row["segment"] || row["text"]
        beg = row["starts"] || row["beg"]
        end_val = row["ends"] || row["end"]
        turn = row["turn"]

        # Normalize filename: sw#### -> sw0#### (only if exactly 4 digits)
        if filename && filename.match?(/sw\d{4}(?!\d)/)
          original = filename
          filename = filename.sub(/sw(\d{4})/, 'sw0\1')
          Rails.logger.info "Normalized filename: #{original} -> #{filename}"
        end

        Segment.create!(
          filename: filename,
          channel: channel,
          beg: beg,
          end: end_val,
          turn: turn,
          text: text
        )
        imported_count += 1
      end

      uploaded_db.close
      Rails.logger.info "Successfully imported #{imported_count} segments"
      redirect_to segments_path, notice: "Successfully imported #{imported_count} segments."
    rescue => e
      Rails.logger.error "Error importing: #{e.class}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      redirect_to segments_path, alert: "Error importing data: #{e.message}"
    ensure
      File.delete(temp_path) if File.exist?(temp_path)
      Rails.logger.info "=== SEGMENTS UPLOAD DEBUG END ==="
    end
  end

  # DELETE /segments/delete_all
  def delete_all
    count = Segment.count
    Segment.delete_all
    redirect_to segments_path, notice: "Successfully deleted #{count} segments."
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_segment
      @segment = Segment.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def segment_params
      params.expect(segment: [ :filename, :channel, :beg, :end, :turn, :text ])
    end
end
