# frozen_string_literal: true

class ComponentsController < ApplicationController
  def index
    # This controller is just for displaying components in the browser
  end

  layout -> { ApplicationLayout }, only: [:phlex, :dashboard]

  def phlex
    # For testing Phlex components
    render ExamplesView.new
  end

  def dashboard
    @releases = [
      {id: 1, name: "API Gateway", version: "2.4.1", environment: :production, status: :deployed},
      {id: 2, name: "Auth Service", version: "1.9.0", environment: :staging, status: :pending},
      {id: 3, name: "Web Frontend", version: "3.0.0-rc1", environment: :preview, status: :failed},
      {id: 4, name: "Worker Queue", version: "1.2.3", environment: :staging, status: :pending},
      {id: 5, name: "Billing", version: "0.8.4", environment: :production, status: :deployed}
    ]
    render Dashboard::PageComponent.new(releases: @releases)
  end

  def view_component
    # For testing ViewComponent components
  end
end
