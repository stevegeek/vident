# frozen_string_literal: true

module TypedViewComponent
  class GreeterWithTriggerComponent < ApplicationComponent
    renders_one :trigger, GreeterButtonComponent
end

end