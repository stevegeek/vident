class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action do
    Vident::StableId.set_current_sequence_generator(seed: request.fullpath)
  end
  after_action do
    Vident::StableId.clear_current_sequence_generator
  end
end
