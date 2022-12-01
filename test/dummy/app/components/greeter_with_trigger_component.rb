# frozen_string_literal: true

class GreeterWithTriggerComponent < ViewComponent::Base
  include Vident::Component

  renders_one :trigger, GreeterButtonComponent
end
