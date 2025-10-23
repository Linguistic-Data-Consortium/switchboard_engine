module SwitchboardEngine
  class SpeakersController < ApplicationController
    before_action :set_speaker, only: %i[ show edit update destroy ]

    # GET /speakers
    def index
      respond_to do |format|
        format.html
        format.json do
          render json: { speakers: Speaker.all }
        end
      end
    end

    # GET /speakers/1
    def show
    end

    # GET /speakers/new
    def new
      @speaker = Speaker.new
    end

    # GET /speakers/1/edit
    def edit
    end

    # POST /speakers
    def create
      @speaker = Speaker.new(speaker_params)

      if @speaker.save
        redirect_to @speaker, notice: "Speaker was successfully created."
      else
        render :new, status: :unprocessable_content
      end
    end

    # PATCH/PUT /speakers/1
    def update
      if @speaker.update(speaker_params)
        redirect_to @speaker, notice: "Speaker was successfully updated.", status: :see_other
      else
        render :edit, status: :unprocessable_content
      end
    end

    # DELETE /speakers/1
    def destroy
      @speaker.destroy!
      redirect_to speakers_path, notice: "Speaker was successfully destroyed.", status: :see_other
    end

    # POST /speakers/upload
    def upload
      Rails.logger.info "=== UPLOAD DEBUG START ==="
      Rails.logger.info "File present? #{params[:file].present?}"

      unless params[:file].present?
        Rails.logger.info "No file in params"
        redirect_to speakers_path, alert: "No file uploaded."
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

        # Determine which table to use (speakers or metadata)
        table_name = if tables.any? { |t| t["name"] == "speakers" }
          "speakers"
        elsif tables.any? { |t| t["name"] == "metadata" }
          "metadata"
        else
          raise "No 'speakers' or 'metadata' table found in database"
        end

        Rails.logger.info "Using table: #{table_name}"

        # Query from uploaded database
        rows = uploaded_db.execute("SELECT * FROM #{table_name}")
        Rails.logger.info "Found #{rows.length} rows"

        imported_count = 0
        rows.each_with_index do |row, idx|
          Rails.logger.info "Row #{idx}: #{row.inspect}"

          # Normalize filename: sw#### -> sw0#### (only if exactly 4 digits)
          filename = row["filename"]
          if filename && filename.match?(/sw\d{4}(?!\d)/)
            filename = filename.sub(/sw(\d{4})/, 'sw0\1')
            Rails.logger.info "Normalized filename: #{row["filename"]} -> #{filename}"
          end

          Speaker.create!(
            filename: filename,
            channel: row["channel"],
            sex: row["sex"],
            birth_year: row["birth_year"],
            dialect_area: row["dialect_area"],
            education: row["education"],
            topic_description: row["topic_description"]
          )
          imported_count += 1
        end

        uploaded_db.close
        Rails.logger.info "Successfully imported #{imported_count} speakers"
        redirect_to speakers_path, notice: "Successfully imported #{imported_count} speakers."
      rescue => e
        Rails.logger.error "Error importing: #{e.class}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to speakers_path, alert: "Error importing data: #{e.message}"
      ensure
        File.delete(temp_path) if File.exist?(temp_path)
        Rails.logger.info "=== UPLOAD DEBUG END ==="
      end
    end

    # DELETE /speakers/delete_all
    def delete_all
      count = Speaker.count
      Speaker.delete_all
      redirect_to speakers_path, notice: "Successfully deleted #{count} speakers."
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_speaker
        @speaker = Speaker.find(params.expect(:id))
      end

      # Only allow a list of trusted parameters through.
      def speaker_params
        params.expect(speaker: [ :filename, :channel, :sex, :birth_year, :dialect_area, :education, :topic_description ])
      end
  end
end
