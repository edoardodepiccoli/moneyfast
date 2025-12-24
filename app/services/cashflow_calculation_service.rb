class CashflowCalculationService
  def initialize(user)
    @user = user
    @processed_transactions = user.transactions.processed
  end

  def summary
    today = Date.today
    current_transactions = @processed_transactions.past
    future_transactions = @processed_transactions.future

    total_net_worth = current_transactions.sum(:amount) || 0
    future_expenses = future_transactions.expenses.sum(:amount) || 0
    future_income = future_transactions.income.sum(:amount) || 0
    usable_net_worth = total_net_worth + future_expenses + future_income

    {
      total_net_worth: total_net_worth,
      future_expenses: future_expenses,
      future_income: future_income,
      usable_net_worth: usable_net_worth,
      future_transactions_count: future_transactions.count
    }
  end

  def detail
    monthly_cashflow = calculate_monthly_cashflow
    monthly_breakdown = calculate_monthly_breakdown
    totals = calculate_totals
    averages = calculate_averages(monthly_cashflow, monthly_breakdown)
    monthly_trends = calculate_monthly_trends(monthly_cashflow)
    overall_trend = calculate_overall_trend(monthly_cashflow)

    {
      total_cashflow: totals[:total],
      total_ins: totals[:ins],
      total_outs: totals[:outs],
      monthly_cashflow: monthly_cashflow,
      monthly_breakdown: monthly_breakdown,
      average_cashflow: averages[:cashflow],
      average_ins: averages[:ins],
      average_outs: averages[:outs],
      monthly_trends: monthly_trends,
      overall_trend: overall_trend,
      max_amount_for_chart: calculate_max_amount_for_chart(monthly_cashflow)
    }
  end

  private

  def calculate_monthly_cashflow
    @processed_transactions
      .group("strftime('%Y-%m', date)")
      .sum(:amount)
      .transform_keys { |key| Date.parse("#{key}-01") }
      .sort_by { |month, _| month }
      .reverse
      .to_h
  end

  def calculate_monthly_breakdown
    # Get all transactions grouped by month
    transactions_by_month = @processed_transactions
      .select("date, amount, category")
      .group_by { |t| t.date.beginning_of_month }

    transactions_by_month.transform_values do |transactions|
      ins_transactions = transactions.select { |t| t.amount > 0 }
      outs_transactions = transactions.select { |t| t.amount < 0 }

      ins_total = ins_transactions.sum(&:amount) || 0
      outs_total = outs_transactions.sum(&:amount) || 0

      ins_by_category = ins_transactions
        .group_by(&:category)
        .transform_values { |txs| txs.sum(&:amount) }
        .sort_by { |_, amount| -amount }
        .to_h

      outs_by_category = outs_transactions
        .group_by(&:category)
        .transform_values { |txs| txs.sum(&:amount) }
        .sort_by { |_, amount| amount }
        .to_h

      {
        ins: ins_total,
        outs: outs_total,
        count: transactions.size,
        ins_by_category: ins_by_category,
        outs_by_category: outs_by_category
      }
    end.sort_by { |month, _| month }.reverse.to_h
  end

  def calculate_totals
    {
      total: @processed_transactions.sum(:amount) || 0,
      ins: @processed_transactions.income.sum(:amount) || 0,
      outs: @processed_transactions.expenses.sum(:amount) || 0
    }
  end

  def calculate_averages(monthly_cashflow, monthly_breakdown)
    average_cashflow = monthly_cashflow.any? ? (monthly_cashflow.values.sum.to_f / monthly_cashflow.size) : 0

    if monthly_breakdown.any?
      months_count = monthly_breakdown.size
      total_ins = monthly_breakdown.values.sum { |data| data[:ins] }
      total_outs = monthly_breakdown.values.sum { |data| data[:outs] }

      average_ins = total_ins.to_f / months_count
      average_outs = total_outs.to_f / months_count
    else
      average_ins = 0
      average_outs = 0
    end

    {
      cashflow: average_cashflow,
      ins: average_ins,
      outs: average_outs
    }
  end

  def calculate_monthly_trends(monthly_cashflow)
    trends = {}
    monthly_array = monthly_cashflow.to_a

    monthly_array.each_with_index do |(month, amount), index|
      next if index >= monthly_array.size - 1

      previous_amount = monthly_array[index + 1][1]
      if previous_amount != 0
        change = ((amount - previous_amount) / previous_amount.abs) * 100
        trends[month] = change
      else
        trends[month] = amount > 0 ? 100 : (amount < 0 ? -100 : 0)
      end
    end

    trends
  end

  def calculate_overall_trend(monthly_cashflow)
    monthly_array = monthly_cashflow.to_a

    if monthly_array.size >= 6
      recent_3_months = monthly_array[0..2].map { |_, amount| amount }.sum
      previous_3_months = monthly_array[3..5].map { |_, amount| amount }.sum
      previous_3_months != 0 ? ((recent_3_months - previous_3_months) / previous_3_months.abs) * 100 : 0
    elsif monthly_array.size >= 2
      recent_avg = monthly_array[0..[1, monthly_array.size - 1].min].map { |_, amount| amount }.sum.to_f / [2, monthly_array.size].min
      previous_avg = monthly_array[[2, monthly_array.size - 1].min..-1].map { |_, amount| amount }.sum.to_f / [monthly_array.size - 2, 1].max
      previous_avg != 0 ? ((recent_avg - previous_avg) / previous_avg.abs) * 100 : 0
    else
      0
    end
  end

  def calculate_max_amount_for_chart(monthly_cashflow)
    return 0 if monthly_cashflow.empty?

    amounts = monthly_cashflow.values.map(&:abs).sort
    percentile_index = [(amounts.size * 0.90).ceil - 1, 0].max
    amounts[percentile_index] || 0
  end
end

