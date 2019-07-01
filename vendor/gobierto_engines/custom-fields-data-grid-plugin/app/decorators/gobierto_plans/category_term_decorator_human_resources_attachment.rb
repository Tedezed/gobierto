module GobiertoPlans
  module CategoryTermDecoratorHumanResourcesAttachment

    extend ActiveSupport::Concern

    private

    def node_plugins_data(node)
      super_result = super

      super_result[:human_resources] = {
        title_translations: Hash[I18n.available_locales.map do |locale|
          [locale, I18n.t("gobierto_plans.custom_fields_plugins.human_resources.title", locale: locale)]
        end],
        budgeted_amount: nil,
        executed_amount: nil,
        executed_percentage: nil
      }

      human_resources_fields = site.custom_fields.where(
        "options @> ?",
        { configuration: { plugin_type: "human_resources" } }.to_json
      )
      records = node.custom_field_records.where(custom_field: human_resources_fields)
      records_functions = records.map { |r| r.functions(version: node.published_version) }

      return super_result if records_functions.empty?

      total_cost = records_functions.map(&:planned_cost).sum
      total_executed = records_functions.map(&:executed_cost).sum

      super_result[:human_resources][:budgeted_amount] = total_cost.round
      super_result[:human_resources][:executed_amount] = total_executed.round
      super_result[:human_resources][:executed_percentage] = "#{((total_executed * 100) / total_cost).round} %"

      super_result
    end

  end
end
