# frozen_string_literal: true

module GobiertoPeople
  class DepartmentsController < GobiertoPeople::ApplicationController
    include DatesRangeHelper

    DEFAULT_LIMIT = 10
    before_action :check_active_submodules

    def index
      @departments = site_departments

      if current_site.date_filter_configured?
        @departments = QueryWithEvents.new(
          source: site_departments,
          start_date: filter_start_date,
          end_date: filter_end_date
        )
      end

      event_attendances_within_range = QueryWithEvents.new(
        source: current_site.event_attendances,
        start_date: filter_start_date,
        end_date: filter_end_date,
        not_null: [:department_id]
      )

      @departments_count = @departments.count
      @total_events = event_attendances_within_range.count
      @total_people = event_attendances_within_range.pluck(:person_id).uniq.count
    end

    def show
      @department = DepartmentDecorator.new(
        site_departments.find_by_slug!(params[:id]),
        filter_start_date: filter_start_date,
        filter_end_date: filter_end_date
      )

      @department_stats = @department.stats
    end

    def check_active_submodules
      redirect_to gobierto_people_root_path unless departments_submodule_active?
    end

    protected

    def site_departments
      current_site.departments
    end

    def events_model
      GobiertoCalendars::Event
    end

    def events_table
      events_model.table_name
    end
  end
end
