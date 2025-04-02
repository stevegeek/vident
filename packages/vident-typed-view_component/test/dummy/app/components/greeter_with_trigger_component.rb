# frozen_string_literal: true

class GreeterWithTriggerComponent < ApplicationComponent
  renders_one :trigger, GreeterButtonComponent
end
