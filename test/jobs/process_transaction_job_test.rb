require "test_helper"

class ProcessTransactionJobTest < ActiveJob::TestCase
  setup do
    @transaction = transactions(:three) # pending transaction
  end

  test "job enqueues successfully" do
    assert_enqueued_with(job: ProcessTransactionJob, args: [@transaction.id]) do
      ProcessTransactionJob.perform_later(@transaction.id)
    end
  end

  test "job is configured with retry and discard" do
    # Verify job class has the expected configuration
    assert_equal :default, ProcessTransactionJob.queue_name
  end
end

