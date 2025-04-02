# frozen_string_literal: true

class ComponentsController < ApplicationController
  def index
    # This controller is just for displaying components in the browser
  end

  layout -> { ApplicationLayout }, only: [:phlex, :typed_phlex]

  def phlex
    # For testing Phlex components
    render ApplicationIndexView.new
  end

  def typed_phlex
    # For testing Typed Phlex components
    render TypedPhlex::ApplicationIndexView.new
  end

  def view_component
    # For testing ViewComponent components
  end

  def typed_view_component
    # For testing Typed ViewComponent components
  end
end
