class ApplicationController < ActionController::Base
  prepend_before_action do
    Vident::StableId.set_current_sequence_generator
  end
end
