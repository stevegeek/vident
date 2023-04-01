class ApplicationController < ActionController::Base
  layout -> { ApplicationLayout }

  prepend_before_action do
    Vident::StableId.set_current_sequence_generator
  end

  def index
    render ApplicationIndexView.new
  end
end
