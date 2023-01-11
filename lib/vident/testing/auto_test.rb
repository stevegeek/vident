# frozen_string_literal: true

require "minitest/hooks"

module Vident
  module Testing
    module AutoTest
      extend ActiveSupport::Concern

      included do
        include Minitest::Hooks

        def before_all
          @results_content = []
          ::Vident::StableId.set_current_sequence_generator
        end

        def after_all
          html = <<~HTML
            <!doctype html>
            <html lang="en">
            <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
            <meta http-equiv="X-UA-Compatible" content="ie=edge">
            <title>Test run output</title>
            </head>
            <body>
              #{@results_content.map(&:to_s).join("<hr>\n").html_safe}
            </body>
            </html>
          HTML

          # TODO: configurable layout
          filename = self.class.name.gsub("::", "_")
          File.write("render_results_#{filename}.html", html) # TODO: path for outputs (eg default tmp/)
        end
      end

      class_methods do
        def auto_test(class_under_test, **param_config)
          attribute_tester = Vident::Testing::AttributesTester.new(param_config)
          attribute_tester.valid_configurations.each_with_index do |test, index|
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def test_renders_with_valid_attrs_#{index}
                test_attrs = #{test}
                begin 
                  @results_content << render_inline(#{class_under_test}.new(**test_attrs))
                rescue => error
                  assert(false, "Should not raise with #{test.to_s.tr("\"", "'")} but did raise \#{error}")
                end
              end
            RUBY
          end

          attribute_tester.invalid_configurations.each_with_index do |test, index|
            class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
              def test_raises_with_invalid_attrs_#{index}
                test_attrs = #{test}
                assert_raises(StandardError, "Should raise with #{test.to_s.tr("\"", "'")}") do
                  @results_content << render_inline(#{class_under_test}.new(**test_attrs))
                end
              end
            RUBY
          end
        end
      end
    end
  end
end
