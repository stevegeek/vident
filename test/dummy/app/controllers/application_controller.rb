class ApplicationController < ActionController::Base
  prepend_before_action do
    Vident::StableId.set_current_sequence_generator
  end

  def index
    render Views::HelloView.new(name: "World")
  end

  def example2
    render Views::HelloView.new(name: "World 2", element_tag: :aside, html_options: {class: "bg-black", style: "background: black; color: white"})
  end
end
