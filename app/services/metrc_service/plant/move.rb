require_relative '../../common/plant_resource_triggers'

module MetrcService
  module Plant
    class Move < Base
      include Common::PlantResourceTriggers

      GROWTH_CYCLES = {
        clone: %i[clone vegetative],
        vegetative: %i[vegetative flowering],
        flowering: %i[flowering]
      }.freeze

      DEFAULT_MOVE_STEP = :change_growth_phase

      def call
        log("Next step: #{next_step_name}. Batch ID #{@batch_id}, completion ID #{@completion_id}")

        send(next_step_name)

        handle_resources

        success!
      end

      def transaction
        @transaction ||= get_transaction(:move_batch, @attributes.merge(sub_stage: batch.zone.sub_stage.attributes))
      end

      def prior_move_transactions
        Transaction.where(
          'batch_id = ? AND type = ? AND vendor = ? AND id NOT IN (?)',
          @batch_id,
          :move_batch,
          :metrc,
          transaction.id
        )
      end

      private

      def next_step_name
        transactions = prior_move_transactions
        return DEFAULT_MOVE_STEP if transactions.count.zero?

        previous_growth_phase = normalized_growth_phase(transactions.last.metadata.dig('sub_stage', 'name'))

        # Does last move includes new move?
        is_included = is_included?(previous_growth_phase, normalized_growth_phase)
        log("Transactions: #{transactions.size}, Previous growth phase: #{previous_growth_phase}, Growth phase is included: #{is_included}, Batch ID #{@batch_id}, completion ID #{@completion_id}")

        raise InvalidOperation, "Failed: Substage #{normalized_growth_phase} is not a valid next phase for #{previous_growth_phase}. Batch ID #{@batch_id}, completion ID #{@completion_id}" \
          unless is_included

        next_step(previous_growth_phase, normalized_growth_phase)
      end

      def is_included?(previous_growth_phase, growth_phase) # rubocop:disable Naming/PredicateName
        GROWTH_CYCLES[previous_growth_phase.downcase.to_sym]&.include?(growth_phase.downcase.to_sym)
      end

      def next_step(previous_growth_phase = nil, new_growth_phase = nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        return DEFAULT_MOVE_STEP if previous_growth_phase.nil? || new_growth_phase.nil?

        new_growth_phase.downcase!

        return :move_plant_batches if previous_growth_phase.include?('clone') && new_growth_phase.include?('clone')

        return :move_plants if previous_growth_phase.include?('veg') && new_growth_phase.include?('veg')

        return :move_plants if previous_growth_phase.include?('flow') && new_growth_phase.include?('flow')

        # clone -> veg
        # veg -> flow
        # any other case
        #
        # -> default

        DEFAULT_MOVE_STEP
      end

      def move_plants
        payload = items.map do |item|
          {
            Id: nil,
            Label: item.relationships.dig('barcode', 'data', 'id'),
            Location: batch.zone.name,
            ActualDate: start_time
          }
        end

        call_vendor(:move_plants, payload)
      end

      def move_plant_batches
        payload = {
          Name: batch_tag,
          Location: batch.zone.name,
          MoveDate: start_time
        }

        call_vendor(:move_plant_batches, [payload])
      end

      def change_growth_phase
        first_tag_id = items.first.id
        barcode      = items.find { |item| item.id == first_tag_id }.relationships.dig('barcode', 'data', 'id')

        payload = {
          Name: batch_tag,
          Count: batch.quantity.to_i,
          StartingTag: immature? ? nil : barcode,
          GrowthPhase: normalized_growth_phase,
          NewLocation: batch.zone.name,
          GrowthDate: start_time,
          PatientLicenseNumber: nil
        }

        call_vendor(:change_growth_phase, [payload])
      end

      def items
        @items ||= get_items(batch.seeding_unit.id)
      end

      def start_time
        @attributes.dig('start_time')
      end

      def immature?
        normalized_growth_phase != 'Flowering'
      end

      def normalized_growth_phase(input = nil)
        input ||= batch.zone.sub_stage.name

        case input
        when /veg/i
          'Vegetative'
        when /flow/i
          'Flowering'
        else
          'Clone'
        end
      end
    end
  end
end
