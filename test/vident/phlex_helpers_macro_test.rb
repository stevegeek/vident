# frozen_string_literal: true

require "test_helper"

class PhlexHelpersMacroTest < ViewComponent::TestCase
  class WithNumberHelper < Vident::Phlex::HTML
    phlex_helpers :number_with_precision

    prop :amount, _Any

    stimulus do
      values price: -> { number_with_precision(@amount, precision: 2) }
    end

    def view_template
      root_element { plain "x" }
    end
  end

  def test_bare_helper_call_from_dsl_proc
    output = WithNumberHelper.new(amount: 1.5).render_in(vc_test_controller.view_context)
    assert_match(/price-value="1\.50"/, output)
  end

  def test_unknown_helper_raises_at_class_definition
    assert_raises(ArgumentError, /No Phlex::Rails::Helpers/) do
      Class.new(Vident::Phlex::HTML) { phlex_helpers :definitely_not_a_helper }
    end
  end
end
