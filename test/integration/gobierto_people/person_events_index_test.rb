require "test_helper"

module GobiertoPeople
  class PersonEventsIndexTest < ActionDispatch::IntegrationTest
    def setup
      super
      @path = gobierto_people_events_path
      @path_for_json = gobierto_people_events_path(format: :json)
      @path_for_csv = gobierto_people_events_path(format: :csv)
    end

    def site
      @site ||= sites(:madrid)
    end

    def government_member
      gobierto_people_people(:richard)
    end

    def executive_member
      gobierto_people_people(:tamara)
    end

    def people
      @people ||= [government_member, executive_member]
    end

    def political_groups
      @political_groups ||= [
        gobierto_people_political_groups(:marvel),
        gobierto_people_political_groups(:dc)
      ]
    end

    def upcoming_events
      @upcoming_events ||= [
        gobierto_people_person_events(:richard_published)
      ]
    end

    def past_events
      @past_events ||= [
        gobierto_people_person_events(:richard_published_past),
        gobierto_people_person_events(:tamara_published_past)
      ]
    end

    def upcoming_event
      @upcoming_event ||= upcoming_events.first
    end

    def create_event(options = {})
      GobiertoPeople::PersonEvent.create!(
        person: options[:person] || government_member,
        title: options[:title] || "Event title",
        description: "Event description",
        starts_at: Time.zone.parse(options[:starts_at]) || Time.zone.now,
        ends_at:  (Time.zone.parse(options[:starts_at]) || Time.zone.now) + 1.hour,
        state: GobiertoPeople::PersonEvent.states["published"]
      )
    end

    def test_person_events_index
      with_current_site(site) do
        visit @path

        assert has_selector?("h2", text: "#{site.name}'s member agendas")
      end
    end

    def test_person_events_filter
      with_current_site(site) do
        visit @path

        within ".filter_boxed" do
          assert has_link?("Government Team")
          assert has_link?("Opposition")
          assert has_link?("Executive")
          assert has_link?("All")
        end
      end
    end

    def test_person_events_filter_for_agenda_switcher
      with_current_site(site) do
        visit @path

        click_link "All"

        within ".agenda-switcher" do
          assert has_link? government_member.name
          assert has_link? executive_member.name
        end

        click_link "Government Team"

        within ".agenda-switcher" do
          assert has_link? government_member.name
          refute has_link? executive_member.name
        end

        click_link "Opposition"

        within ".agenda-switcher" do
          refute has_link? government_member.name
          refute has_link? executive_member.name
        end

      end
    end

    def test_person_events_filter_for_calendar_widget
      government_event = create_event(person: government_member, starts_at: "2017-03-16")
      executive_event  = create_event(person: executive_member,  starts_at: "2017-03-17")

      government_event_day = government_event.starts_at.day
      executive_event_day  = executive_event.starts_at.day

      Timecop.freeze(Time.zone.parse("2017-03-15")) do
        with_current_site(site) do
          visit @path

          click_link "All"

          within ".calendar-component" do
            assert has_link? government_event_day
            assert has_link? executive_event_day
          end

          click_link "Government Team"

          within ".calendar-component" do
            assert has_link? government_event_day
            refute has_link? executive_event_day
          end

          click_link "Opposition"

          within ".calendar-component" do
            refute has_link? government_event_day
            refute has_link? executive_event_day
          end

        end
      end
    end

    def test_person_events_filter_for_events_list
      government_event = create_event(person: government_member, title: "Government event", starts_at: "2017-03-16")
      executive_event  = create_event(person: executive_member,  title: "Executive event",  starts_at: "2017-03-16")

      Timecop.freeze(Time.zone.parse("2017-03-15")) do
        with_current_site(site) do
          visit @path

          click_link "All"

          within ".events-summary" do
            assert has_link?(government_event.title)
            assert has_link?(executive_event.title)
          end

          click_link "Government Team"

          within ".events-summary" do
            assert has_link?(government_event.title)
            refute has_link?(executive_event.title)
          end

          click_link "Opposition"

          within ".events-summary" do
            refute has_link?(government_event.title)
            refute has_link?(executive_event.title)
          end
        end
      end
    end

    def test_events_summary
      with_current_site(site) do
        visit @path

        within ".events-summary" do
          assert has_content?("Agenda")
          assert has_link?("Past events")

          upcoming_events.each do |event|
            assert has_selector?(".person_event-item", text: event.title)
            assert has_link?(event.title)
          end
        end
      end
    end

    def test_events_summary_with_no_upcoming_events
      past_event = create_event(starts_at: "2017-03-14")

      Timecop.freeze(10.years.from_now) do
        with_current_site(site) do
          visit @path

          within ".events-summary" do
            assert_text("There are no future events. Take a look at past ones")
            assert has_link?(past_event.title)
          end
        end
      end
    end

    def test_events_summary_with_no_past_events
      Timecop.freeze(10.years.ago) do
        with_current_site(site) do
          visit @path

          click_link "Past events"

          assert_text("There are no past events.")
        end
      end
    end

    def test_events_summary_with_no_events
      (upcoming_events + past_events).each { |event| event.update_columns(state: :pending) }

      with_current_site(site) do
        visit @path

        assert_text("There are no future or past events.")
      end
    end

    def test_future_and_past_events_filter
      past_event   = create_event(title: "Past event title",   starts_at: "2017-02-15")
      future_event = create_event(title: "Future event title", starts_at: "2017-04-15")

      Timecop.freeze(Time.zone.parse("2017-03-15")) do

        with_current_site(site) do
          visit @path

          within ".events-summary" do
            refute has_content?(past_event.title)
            assert has_content?(future_event.title)
          end

          click_link "Past events"

          within ".events-summary" do
            assert has_content?(past_event.title)
            refute has_content?(future_event.title)
          end
        end

      end
    end

    def test_future_and_past_events_filter_is_kept_when_changing_political_group
      with_current_site(site) do
        visit @path

        within ".events-summary .events-filter" do
          assert has_link? "Past events"
          refute has_link? "Agenda"
        end

        click_link "Past events"
        click_link "Government Team"

        within ".events-summary .events-filter" do
          refute has_link? "Past events"
          assert has_link? "Agenda"
        end

        click_link "Agenda"
        click_link "Executive"

        within ".events-summary .events-filter" do
          assert has_link? "Past events"
          refute has_link? "Agenda"
        end
      end
    end

    def test_calendar_component
      future_event = create_event(starts_at: "2017-03-16")

      Timecop.freeze(Time.zone.parse("2017-03-15")) do
        with_current_site(site) do
          visit gobierto_people_events_path(start_date: future_event.starts_at)

          within ".calendar-component" do
            assert has_link?(future_event.starts_at.day)
          end
        end
      end
    end

    def test_calendar_navigation_arrows
      past_event   = create_event(starts_at: "2017-02-15")
      future_event = create_event(starts_at: "2017-04-15")

      Timecop.freeze(Time.zone.parse("2017-03-15")) do

        with_current_site(site) do
          visit gobierto_people_events_path

          click_link "next-month-link"

          within ".calendar-component" do
            assert has_link?(future_event.starts_at.day)
          end

          visit gobierto_people_events_path

          click_link "previous-month-link"

          within ".calendar-component" do
            assert has_link?(past_event.starts_at.day)
          end
        end

      end
    end

    def test_calendar_event_links
      visible_month_events = ["2017-02-28", "2017-03-14", "2017-03-16", "2017-04-01"].map do |date|
        create_event(starts_at: date)
      end

      Timecop.freeze(Time.zone.parse("2017-03-15")) do

        with_current_site(site) do
          visit gobierto_people_events_path

          within ".calendar-component" do
            visible_month_events.each do |event|
              assert has_link?(event.starts_at.day)
            end
          end

        end

      end
    end

    def test_agenda_switcher
      with_current_site(site) do
        visit @path

        within ".agenda-switcher" do
          people.each do |person|
            assert has_link?(person.name)
          end
        end
      end
    end

    def test_subscription_block
      with_current_site(site) do
        visit @path

        within ".subscribable-box", match: :first do
          assert has_button?("Subscribe")
        end
      end
    end

    def test_person_events_index_json
      with_current_site(site) do
        get @path_for_json

        json_response = JSON.parse(response.body)
        assert_equal json_response.first["person_name"], "Richard Rider"
        assert_equal json_response.first["title"], "Junta de Gobierno"
        assert_equal json_response.first["description"], "El Presidente analizará la marcha de las medidas adoptadas en los primeros días de Gobierno."
      end
    end

    def test_person_events_index_csv
      with_current_site(site) do
        get @path_for_csv

        csv_response = CSV.parse(response.body, headers: true)
        assert_equal csv_response.by_row[0]["person_name"], "Richard Rider"
        assert_equal csv_response.by_row[0]["title"], "Junta de Gobierno"
        assert_equal csv_response.by_row[0]["description"], "El Presidente analizará la marcha de las medidas adoptadas en los primeros días de Gobierno."
      end
    end
  end
end
