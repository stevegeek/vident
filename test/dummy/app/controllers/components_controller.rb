# frozen_string_literal: true

class ComponentsController < ApplicationController
  def index
    # This controller is just for displaying components in the browser
  end

  layout -> { ApplicationLayout }, only: [:phlex, :tasks]

  def phlex
    # For testing Phlex components
    render ExamplesView.new
  end

  def tasks
    @tasks = [
      {id: 1, title: "Write the launch announcement", due: "Today", list: :today, status: :todo},
      {id: 2, title: "Migrate the legacy importer", due: "Wed", list: :this_week, status: :done},
      {id: 3, title: "Add Stripe webhooks", due: "—", list: :backlog, status: :wont_do},
      {id: 4, title: "Cut the v2.1 release", due: "Fri", list: :this_week, status: :todo},
      {id: 5, title: "Onboarding playbook draft", due: "Mon", list: :backlog, status: :todo}
    ]
    render Tasks::PageComponent.new(tasks: @tasks)
  end

  def view_component
    # For testing ViewComponent components
  end
end
