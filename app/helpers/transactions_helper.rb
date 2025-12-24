module TransactionsHelper
  def transaction_status_badge_class(transaction)
    if transaction.pending?
      "badge-warning"
    elsif transaction.failed?
      "badge-error"
    else
      "badge-success"
    end
  end

  def transaction_amount_class(amount)
    amount >= 0 ? "text-success" : "text-error"
  end

  def transaction_card_class(transaction)
    if transaction.pending?
      "bg-warning/10 border border-warning/30"
    elsif transaction.scheduled?
      "bg-warning/20 border border-warning/40"
    else
      "bg-base-200 border border-base-300"
    end
  end

  def format_transaction_date(date)
    return "" if date.blank?
    date.strftime("%A %-d %B %Y")
  end

  def format_transaction_month(date)
    return "" if date.blank?
    date.strftime("%b %Y")
  end
end
