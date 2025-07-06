# frozen-string-literal: true

class ExamplesView < ApplicationView
  def view_template
    div(class: "space-y-6") do
      h1(class: "text-3xl") { "Comparing components" }
      div(class: "space-y-16") do
        h2(class: "text-xl") { "Stimulus Greeter Examples" }
        section(class: "space-y-8") do
          h3(class: "text-md font-bold") { "A plain old Phlex::HTML" }
          code(class: "block bg-gray-100") do
            %(render ::PhlexGreeters::GreeterComponent.new(cta: "Greet w. Phlex::HTML"))
          end
          render PhlexGreeters::GreeterComponent.new(cta: "Greet w. Phlex::HTML")
          h3(class: "text-md font-bold") { "A Phlex::HTML with Vident" }
          code(class: "block bg-gray-100") do
            %(render ::PhlexGreeters::GreeterVidentComponent.new(cta: "Greet w. Vident + Phlex::HTML"))
          end
          render PhlexGreeters::GreeterVidentComponent.new(
            cta: "Greet w. Vident + Phlex::HTML"
          )
          h3(class: "text-md font-bold") do
            "An example of a component where we use Vident to set Stimulus actions/targets on other components"
          end
          pre do
            %(
<%= render ::PhlexGreeters::GreeterWithTriggerComponent.new do |greeter| %>
  <% greeter.trigger(
     before_clicked_message: "I'm a button component!",
     after_clicked_message: "Greeted! Click me again to reset.",
     actions: [
       greeter.stimulus_action(:click, :greet),
     ],
     classes: "bg-red-500 hover:bg-red-700",
     html_options: {
       role: "button"
     }
   ) %>
<% end %>
)
          end
          render PhlexGreeters::GreeterWithTriggerComponent.new do |greeter|
            greeter.trigger(
              before_clicked_message: "I'm a button, click me!",
              after_clicked_message: "Greeted! Click me again to reset.",
              stimulus_actions: [greeter.stimulus_action(:click, :greet)],
              classes: "bg-red-500 hover:bg-red-700",
              html_options: {
                role: "button"
              }
            )
          end
        end
        h2(class: "text-xl pt-6") { "Rendering the AvatarComponent" }
        section(class: "space-y-16") do
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") { "with initials" }
            code(class: "block bg-gray-100") do
              %(render ::AvatarComponent.new(initials: "AB"))
            end
            div(class: "block") { render Phlex::AvatarComponent.new(initials: "AB") }
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with a value of invalid type passed to attributes, will raise an error."
            end
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(initials: 123, size: "foo"))
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(initials: 123, size: "foo")
            rescue
              "A type error was thrown as expected!"
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") { "with image" }
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(url: "https://i.pravatar.cc/300", initials: "AB"))
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(
                url: "https://i.pravatar.cc/300",
                initials: "AB"
              )
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") { "with image and x_large size" }
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(url: "https://i.pravatar.cc/300", initials: "AB", size: :x_large))
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(
                url: "https://i.pravatar.cc/300",
                initials: "AB",
                size: :x_large
              )
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with image and alt and class set at render site (ring)"
            end
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(url: "https://i.pravatar.cc/300", initials: "AB", html_options: {alt: "My alt text", classes: "ring-2 ring-red-900"}))
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(
                url: "https://i.pravatar.cc/300",
                initials: "AB",
                classes: "ring-2 ring-red-900",
                html_options: {
                  alt: "My alt text"
                }
              )
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with initials and small size and border"
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(
                initials: "SG",
                size: :small,
                border: true
              )
            end
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(initials: "SG", size: :small, border: true))
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with initials and square shape and custom border color (note if using Tailwind you will want to use `vident-tailwind` too to correctly override classes like this)"
            end
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(initials: "SG", shape: :square, classes: "border-2 border-red-600"))
            end
            div(class: "block") do
              render Phlex::AvatarComponent.new(
                initials: "SG",
                shape: :square,
                classes: "border-2 border-red-600"
              )
            end
          end

          p { "Render an avatar" }
          render Phlex::AvatarComponent.new(initials: "V C")
          br
          component = Phlex::AvatarComponent.new(initials: "V C",  classes: "bg-red-900")
          p {
            "The following example sets a background color override using a tailwind utility class (note that sometimes you will find overrides don't work due to CSS specificity. To solve this use the `vident-tailwind` module in your component!)"
          }
          render component
          br
          p { "Components can also have a `#cache_key` method which plays nicely with fragment caching." }
          p { "Cache Key for above component:" }
          pre { component.cache_key }
          p { "Cache Key for Avatar component with different attributes:" }
          pre { Phlex::AvatarComponent.new(initials: "V C").cache_key }
        end
      end
    end
  end
end
