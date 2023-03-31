require "vident/better_html/version"
require "vident/better_html/railtie"

require "cgi/util"

module Vident
  module BetterHtml
    module RootComponent
      # Return the HTML `data-controller` attribute for the given controllers
      def with_controllers(*controllers_to_set)
        helpers.html_attributes("data-controller" => controller_list(controllers_to_set)&.html_safe)
      end

      # Return the HTML `data-target` attribute for the given targets
      def as_targets(*targets)
        attrs = build_target_data_attributes(parse_targets(targets))
        helpers.html_attributes(attrs.transform_keys! { |k| "data-#{k}" })
      end
      alias_method :as_target, :as_targets

      # Return the HTML `data-action` attribute for the given actions
      def with_actions(*actions_to_set)
        actions_str = action_list(actions_to_set)
        actions_str.present? ? helpers.html_attributes("data-action" => actions_str) : nil
      end
      alias_method :with_action, :with_actions

      private

      # Complete list of actions ready to be use in the data-action attribute
      def action_list(actions_to_parse)
        return nil unless actions_to_parse&.size&.positive?
        # `html_attributes` will escape '->' thus breaking the stimulus action, so we need to do our own escaping
        actions_str_raw = parse_actions(actions_to_parse).join(" ")
        CGI.escapeHTML(actions_str_raw).gsub("-&gt;", "->").html_safe
      end
    end
  end
end
