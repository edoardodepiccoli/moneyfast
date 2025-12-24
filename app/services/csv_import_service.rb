class CsvImportService
  Result = Struct.new(:success?, :imported_count, :errors, :error_message, keyword_init: true)

  def initialize(user, file)
    @user = user
    @file = file
  end

  def call
    return missing_file_result if @file.nil?

    begin
      require "csv"
      csv_content = normalize_encoding(@file.read)
      csv = CSV.parse(csv_content, headers: true, header_converters: :symbol)

      return invalid_headers_result unless valid_headers?(csv)

      import_transactions(csv)
    rescue CSV::MalformedCSVError => e
      Result.new(success?: false, error_message: "Invalid CSV file: #{e.message}")
    rescue => e
      Result.new(success?: false, error_message: "Error importing file: #{e.message}")
    end
  end

  private

  def normalize_encoding(content)
    if content.encoding == Encoding::ASCII_8BIT
      content = content.force_encoding("UTF-8")
    end
    content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  end

  def valid_headers?(csv)
    required_headers = %i[date amount description]
    required_headers.all? { |header| csv.headers.include?(header) }
  end

  def import_transactions(csv)
    imported_count = 0
    errors = []
    row_number = 1

    csv.each do |row|
      row_number += 1
      result = import_row(row, row_number)
      if result[:success]
        imported_count += 1
      else
        errors << result[:error]
      end
    end

    build_result(imported_count, errors)
  end

  def import_row(row, row_number)
    transaction = @user.transactions.build(
      date: Date.parse(row[:date]),
      amount: BigDecimal(row[:amount]),
      description: row[:description],
      raw_input: row[:description],
      status: :processed
    )

    if transaction.save
      { success: true }
    else
      { success: false, error: "Row #{row_number}: #{transaction.errors.full_messages.join(', ')}" }
    end
  rescue => e
    { success: false, error: "Row #{row_number}: #{e.message}" }
  end

  def build_result(imported_count, errors)
    if errors.empty?
      Result.new(
        success?: true,
        imported_count: imported_count,
        error_message: "Successfully imported #{imported_count} transaction(s)."
      )
    else
      error_count = errors.length
      errors_to_show = errors.first(Moneyfast::MAX_ERRORS_TO_SHOW)
      error_message = "Imported #{imported_count} transaction(s). #{error_count} error(s) occurred."

      if error_count <= Moneyfast::MAX_ERRORS_TO_SHOW
        error_message += " #{errors_to_show.join('; ')}"
      else
        error_message += " First #{Moneyfast::MAX_ERRORS_TO_SHOW} errors: #{errors_to_show.join('; ')}"
      end

      Result.new(
        success?: false,
        imported_count: imported_count,
        errors: errors,
        error_message: error_message
      )
    end
  end

  def missing_file_result
    Result.new(success?: false, error_message: "Please select a CSV file to import.")
  end

  def invalid_headers_result
    Result.new(success?: false, error_message: "CSV file must have columns: date, amount, description")
  end
end
