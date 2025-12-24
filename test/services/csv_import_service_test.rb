require "test_helper"

class CsvImportServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "returns error when file is nil" do
    service = CsvImportService.new(@user, nil)
    result = service.call

    assert_not result.success?
    assert_includes result.error_message, "Please select a CSV file"
  end

  test "returns error when CSV has invalid headers" do
    csv_content = "wrong,headers\n2024-01-01,50,test"
    file = StringIO.new(csv_content)
    file.define_singleton_method(:read) { csv_content }

    service = CsvImportService.new(@user, file)
    result = service.call

    assert_not result.success?
    assert_includes result.error_message, "must have columns"
  end

  test "imports valid CSV successfully" do
    csv_content = "date,amount,description\n2024-01-01,-50.00,Groceries\n2024-01-02,100.00,Payment"
    file = StringIO.new(csv_content)
    file.define_singleton_method(:read) { csv_content }

    service = CsvImportService.new(@user, file)
    result = service.call

    assert result.success?
    assert_equal 2, result.imported_count
  end
end

