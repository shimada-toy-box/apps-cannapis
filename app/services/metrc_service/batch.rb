module MetrcService
  class Batch < MetrcService::Base
    def initialize(ctx, integration, batch = nil, task = nil)
      @task = task
      super(ctx, integration, batch)
    end

    def before
      validate_batch!
    end

    def after; end

    def call
      transactions = completions.each_with_object([]) do |completion, arr|
        ctx = {
          id: completion.id,
          type: :completions,
          attributes: completion.attributes,
          relationships: @relationships
        }.with_indifferent_access

        arr << MetrcService.perform_action(ctx, @integration, @task)

        # halt if the last action failed
        break arr unless arr.last&.success?
      end

      # a stub tranasction to represent the state of the batched transactions
      result = Transaction.new(success: transactions.all?(&:success?))
      @task.delete if result.success?

      result
    end

    def batch
      @batch ||= get_batch
    end

    def validate_batch!
      super
    rescue StandardError
      @task.delete
      raise
    end

    def validate_completions!(completions)
      return if completions.size.positive?

      @task.delete
      raise TransactionAlreadyExecuted, 'batch already processed'
    end

    def completions
      @completions ||= filter_and_validate_completions
    end

    def filter_and_validate_completions
      [].tap do |arr|
        # Filter the completions we curently support
        actions.each do |completion|
          next unless completion_supported?(completion) && !performed_transactions.include?(completion.id)

          arr << completion
        end

        validate_completions!(arr)
      end
    end

    def completion_supported?(completion)
      V1::WebhookController::COMPLETION_TYPES.include?(completion.action_type)
    end

    def performed_transactions
      Transaction.succeed.where(batch_id: batch.id,
                                completion_id: actions.map(&:id),
                                integration: @integration)&.pluck(:completion_id)
    end

    def actions
      @actions ||= batch.completions
    end
  end
end
