# frozen_string_literal: true

require "test_helper"

class StimulusDslProcDefersToRenderTest < ViewComponent::TestCase
  class PhlexUsesHelpers < Vident::Phlex::HTML
    prop :amount, _Any

    stimulus do
      values price: -> { helpers.number_with_precision(@amount, precision: 2) }
    end

    def view_template
      root_element { plain "x" }
    end
  end

  def test_phlex_dsl_proc_can_reach_helpers_at_render_time
    output = PhlexUsesHelpers.new(amount: 1.5).render_in(vc_test_controller.view_context)
    assert_match(/price-value="1\.50"/, output)
  end

  def test_phlex_dsl_proc_does_not_run_at_new_time
    assert_nothing_raised do
      PhlexUsesHelpers.new(amount: 1.5)
    end
  end

  class VcUsesHelpers < Vident::ViewComponent::Base
    prop :amount, _Any

    stimulus do
      values price: -> { helpers.number_with_precision(@amount, precision: 2) }
    end

    def call
      root_element { "x" }
    end
  end

  def test_view_component_dsl_proc_can_reach_helpers_at_render_time
    output = render_inline(VcUsesHelpers.new(amount: 1.5)).to_html
    assert_match(/price-value="1\.50"/, output)
  end

  def test_view_component_dsl_proc_does_not_run_at_new_time
    assert_nothing_raised do
      VcUsesHelpers.new(amount: 1.5)
    end
  end
end
