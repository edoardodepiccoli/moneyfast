namespace :transactions do
  desc "Categorize all undefined transactions using AI"
  task categorize_undefined: :environment do
    undefined_transactions = Transaction.where(category: "undefined")

    if undefined_transactions.empty?
      puts "No undefined transactions found."
      exit
    end

    puts "Found #{undefined_transactions.count} undefined transaction(s). Starting categorization..."

    success_count = 0
    error_count = 0

    undefined_transactions.find_each do |transaction|
      begin
        # Create a formatted input string from the transaction details
        # Format it in a way that helps AI understand we need categorization
        input_text = if transaction.description.present?
          "Transaction: #{transaction.description}. Amount: #{transaction.amount}. Date: #{transaction.date}. Please categorize this transaction."
        else
          "#{transaction.raw_input}. Please categorize this transaction."
        end

        # Use OpenAI service to categorize
        parsed_data = OpenaiParserService.new(input_text).parse

        if parsed_data && parsed_data["category"] && parsed_data["category"] != "undefined"
          transaction.update!(category: parsed_data["category"])
          description_display = transaction.description || transaction.raw_input&.truncate(50)
          puts "✓ Transaction ##{transaction.id}: '#{description_display}' -> #{parsed_data['category']}"
          success_count += 1
        else
          puts "✗ Transaction ##{transaction.id}: Could not determine category"
          error_count += 1
        end

        # Add a small delay to avoid rate limiting
        sleep(0.5)
      rescue StandardError => e
        puts "✗ Transaction ##{transaction.id}: Error - #{e.message}"
        error_count += 1
      end
    end

    puts "\nCategorization complete!"
    puts "Successfully categorized: #{success_count}"
    puts "Failed: #{error_count}"
  end
end
