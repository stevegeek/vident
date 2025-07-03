# frozen_string_literal: true

class ComponentsController < ApplicationController
  def index
    # This controller is just for displaying components in the browser
  end

  layout -> { ApplicationLayout }, only: [:phlex]

  def phlex
    # For testing Phlex components
    render ExamplesView.new
  end

  def view_component
    # For testing ViewComponent components
  end
end
