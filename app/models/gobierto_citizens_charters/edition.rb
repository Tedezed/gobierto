# frozen_string_literal: true

require_dependency "gobierto_citizens_charters"

module GobiertoCitizensCharters
  class Edition < ApplicationRecord
    acts_as_paranoid column: :archived_at

    include ActsAsParanoidAliases

    PERIOD_INTERVAL_DATA = {
      year: ->(date) { { year: date.year } },
      quarter: ->(date) { { quarter: (date.month / 4) + 1, year: date.year } },
      month: ->(date) { { month: date.month, year: date.year } },
      week: ->(date) { { week: date.strftime("%W").to_i, year: date.year } }
    }.freeze

    belongs_to :commitment, -> { with_archived }

    enum period_interval: PERIOD_INTERVAL_DATA.keys

    scope :recent, -> { order(period: :desc) }
    scope :of_same_period, ->(edition) { where(period: (edition.period_start..edition.period_end), period_interval: edition.period_interval) }
    scope :group_by_period_interval, ->(period_interval) { where(period_interval: period_interval).group(Arel.sql("date_trunc('#{ period_interval }', period)"), :period_interval) }

    def proportion
      return nil if percentage.blank? && [value, max_value].any?(&:blank?)

      percentage || 100 * (value / max_value)
    end

    def self.progress
      p_rel = where.not(percentage: nil)
      p_val = where(percentage: nil).where.not(value: nil, max_value: nil)
      (p_rel.sum(:percentage) + p_val.sum("value/max_value") * 100) / (p_rel.count + p_val.count)
    end

    def period_values
      PERIOD_INTERVAL_DATA[period_interval.to_sym].call(period)
    end

    def editions_of_same_period
      self.class.of_same_period(self)
    end

    def period_start
      period.utc.send("at_beginning_of_#{period_interval}")
    end

    def period_end
      period.utc.send("at_end_of_#{period_interval}")
    end

    def previous_period_start
      period_start.send("prev_#{period_interval}")
    end

    def to_s
      period_values.values.join("-")
    end

    def period_front_params
      return {} if [period_interval, period].any?(&:blank?)

      { period_interval: period_interval, period: period_values.values.join("-") }
    end

    def period_admin_params
      return {} if [period_interval, period].any?(&:blank?)

      attributes.slice("period_interval", "period")
    end
  end
end
