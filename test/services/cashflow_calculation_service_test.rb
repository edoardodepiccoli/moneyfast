require "test_helper"

class CashflowCalculationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "summary calculates net worth correctly" do
    service = CashflowCalculationService.new(@user)
    summary = service.summary

    assert summary[:total_net_worth].present?
    assert summary[:usable_net_worth].present?
    assert summary[:future_expenses].present?
    assert summary[:future_income].present?
  end

  test "detail calculates monthly breakdown" do
    service = CashflowCalculationService.new(@user)
    detail = service.detail

    assert detail[:total_cashflow].present?
    assert detail[:total_ins].present?
    assert detail[:total_outs].present?
    assert detail[:monthly_cashflow].is_a?(Hash)
    assert detail[:monthly_breakdown].is_a?(Hash)
  end

  test "detail includes trends" do
    service = CashflowCalculationService.new(@user)
    detail = service.detail

    assert detail[:monthly_trends].is_a?(Hash)
    assert detail[:overall_trend].is_a?(Numeric)
  end
end

