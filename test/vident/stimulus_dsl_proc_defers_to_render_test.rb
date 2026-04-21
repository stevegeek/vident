# frozen_string_literal: true

require "test_helper"

class StimulusDslProcDefersToRenderTest < ActionView::TestCase
  def render(component)
    component.call
  end

  class PhlexUsesHelpers < Vident::Phlex::HTML
    prop :amount, _Any

    stimulus do
      values price: -> { helpers.number_with_precision(amount, precision: 2) }
    end

    def view_template
      root_element { plain "x" }
    end
  end

  def test_phlex_dsl_proc_can_call_helpers
    component = PhlexUsesHelpers.new(amount: 1.5)
    output = render component
    assert_match(/price-value="1\.50"/, output)
  end

  def test_phlex_dsl_proc_does_not_run_at_new_time
    assert_nothing_raised do
      PhlexUsesHelpers.new(amount: 1.5)
    end
  end
end
