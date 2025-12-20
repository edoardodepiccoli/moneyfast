class TransactionsController < ApplicationController
  before_action :authenticate_user!
  def index
    all_transactions = current_user.transactions.recent
    @total_count = all_transactions.count
    @show_all = params[:show_all].present?

    @transactions = @show_all ? all_transactions : all_transactions.limit(10)
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
    file = params[:csv_file]

    if file.nil?
      redirect_to import_export_transactions_path, alert: "Please select a CSV file to import."
      return
    end

    begin
      require "csv"
      # Read file and handle encoding properly
      csv_content = file.read
      # If content is binary/ASCII-8BIT, try to detect and convert to UTF-8
      if csv_content.encoding == Encoding::ASCII_8BIT
        # Try to detect encoding or assume UTF-8
        csv_content = csv_content.force_encoding("UTF-8")
      end
      # Ensure valid UTF-8 by replacing invalid characters
      csv_content = csv_content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
      csv = CSV.parse(csv_content, headers: true, header_converters: :symbol)

      # Check if required columns exist
      unless csv.headers.include?(:date) && csv.headers.include?(:amount) && csv.headers.include?(:description)
        redirect_to import_export_transactions_path, alert: "CSV file must have columns: date, amount, description"
        return
      end

      imported_count = 0
      errors = []
      row_number = 1

      csv.each do |row|
        row_number += 1
        begin
          transaction = current_user.transactions.build(
            date: Date.parse(row[:date]),
            amount: BigDecimal(row[:amount]),
            description: row[:description],
            raw_input: row[:description],
            status: :processed
          )

          if transaction.save
            imported_count += 1
          else
            errors << "Row #{row_number}: #{transaction.errors.full_messages.join(', ')}"
          end
        rescue => e
          errors << "Row #{row_number}: #{e.message}"
        end
      end

      if errors.empty?
        redirect_to import_export_transactions_path, notice: "Successfully imported #{imported_count} transaction(s)."
      else
        error_count = errors.length
        # Limit errors shown to prevent cookie overflow (max ~10 errors)
        max_errors_to_show = 10
        errors_to_show = errors.first(max_errors_to_show)
        error_message = "Imported #{imported_count} transaction(s). #{error_count} error(s) occurred."

        if error_count <= max_errors_to_show
          error_message += " #{errors_to_show.join('; ')}"
        else
          error_message += " First #{max_errors_to_show} errors: #{errors_to_show.join('; ')}"
        end

        redirect_to import_export_transactions_path, alert: error_message
      end
    rescue CSV::MalformedCSVError => e
      redirect_to import_export_transactions_path, alert: "Invalid CSV file: #{e.message}"
    rescue => e
      redirect_to import_export_transactions_path, alert: "Error importing file: #{e.message}"
    end
  end

  def export
    require "csv"

    transactions = current_user.transactions.processed.recent

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "date", "amount", "description" ]

      transactions.each do |transaction|
        csv << [
          transaction.date.strftime("%Y-%m-%d"),
          transaction.amount.to_s,
          transaction.description
        ]
      end
    end

    send_data csv_data,
      filename: "transactions_#{Date.today.strftime('%Y%m%d')}.csv",
      type: "text/csv",
      disposition: "attachment"
  end

  private

  def transaction_params
    params.require(:transaction).permit(:raw_input)
  end
end
