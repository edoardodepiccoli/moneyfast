class CsvExportService
  def initialize(user)
    @user = user
  end

  def generate
    require "csv"

    transactions = @user.transactions.processed.recent

    CSV.generate(headers: true) do |csv|
      csv << %w[date amount description]

      transactions.each do |transaction|
        csv << [
          transaction.date.strftime("%Y-%m-%d"),
          transaction.amount.to_s,
          transaction.description
        ]
      end
    end
  end

  def filename
    "transactions_#{Date.today.strftime('%Y%m%d')}.csv"
  end
end

