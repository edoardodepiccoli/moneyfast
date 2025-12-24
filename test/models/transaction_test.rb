require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "should belong to user" do
    transaction = transactions(:one)
    assert transaction.user.present?
  end

  test "should validate raw_input presence" do
    transaction = Transaction.new(user: users(:one))
    assert_not transaction.valid?
    assert_includes transaction.errors[:raw_input], "can't be blank"
  end

  test "should validate processed transaction has required fields" do
    transaction = Transaction.new(
      user: users(:one),
      raw_input: "test",
      status: :processed
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:amount], "can't be blank"
    assert_includes transaction.errors[:date], "can't be blank"
    assert_includes transaction.errors[:description], "can't be blank"
  end

  test "income? returns true for positive amounts" do
    transaction = transactions(:two)
    assert transaction.income?
  end

  test "expense? returns true for negative amounts" do
    transaction = transactions(:one)
    assert transaction.expense?
  end

  test "scheduled? returns true for future processed transactions" do
    transaction = Transaction.new(
      user: users(:one),
      raw_input: "test",
      status: :processed,
      amount: 100,
      date: 1.week.from_now.to_date,
      description: "future"
    )
    assert transaction.scheduled?
  end

  test "processed scope returns only processed transactions" do
    processed = Transaction.processed
    assert processed.include?(transactions(:one))
    assert processed.include?(transactions(:two))
    assert_not processed.include?(transactions(:three))
  end

  test "income scope returns only positive amounts" do
    income = Transaction.income
    assert income.include?(transactions(:two))
    assert_not income.include?(transactions(:one))
  end

  test "expenses scope returns only negative amounts" do
    expenses = Transaction.expenses
    assert expenses.include?(transactions(:one))
    assert_not expenses.include?(transactions(:two))
  end

  test "future scope returns only future transactions" do
    future_tx = Transaction.create!(
      user: users(:one),
      raw_input: "future",
      status: :processed,
      amount: 100,
      date: 1.week.from_now.to_date,
      description: "future"
    )
    future = Transaction.future
    assert future.include?(future_tx)
    assert_not future.include?(transactions(:one))
  end
end
