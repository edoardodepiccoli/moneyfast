class TransactionsController < ApplicationController
  before_action :authenticate_user!
  def index
    @transactions = current_user.transactions.recent
    @new_transaction = current_user.transactions.build
  end

  def create
    @transaction = current_user.transactions.build(transaction_params)
    @transaction.status = :pending

    if @transaction.save
      ProcessTransactionJob.perform_later(@transaction.id)

      respond_to do |format|
        format.turbo_stream
      end
    end
  end

  def destroy
    @transaction = current_user.transactions.find(params[:id])
    @transaction.destroy

    respond_to do |format|
      format.turbo_stream
    end
  end

  def import_export
    @transactions = current_user.transactions.recent

    render :import_export
  end

  def import
    result = CsvImportService.new(current_user, params[:csv_file]).call

    if result.success?
      redirect_to transactions_path, notice: result.error_message
    else
      redirect_to import_export_transactions_path, alert: result.error_message
    end
  end

  def export
    service = CsvExportService.new(current_user)
    send_data service.generate,
      filename: service.filename,
      type: "text/csv",
      disposition: "attachment"
  end

  def transcribe_audio
    unless params[:audio_file].present?
      render json: { success: false, error: "No audio file provided" }, status: :bad_request
      return
    end

    audio_file = params[:audio_file]
    transcription_result = WhisperTranscriptionService.new(audio_file).transcribe

    unless transcription_result.success?
      render json: { success: false, error: transcription_result.error }, status: :unprocessable_entity
      return
    end

    @transaction = current_user.transactions.build(raw_input: transcription_result.text, status: :pending)

    if @transaction.save
      ProcessTransactionJob.perform_later(@transaction.id)

      # Render the transaction HTML for immediate display
      transaction_html = render_to_string(
        partial: "transactions/transaction_compact",
        locals: { transaction: @transaction },
        formats: [ :html ]
      )

      render json: {
        success: true,
        transaction_id: @transaction.id,
        transaction_html: transaction_html
      }
    else
      render json: { success: false, error: @transaction.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:raw_input)
  end
end
