# frozen-string-literal: true

class TypedPhlex::ExamplesView < TypedPhlex::ApplicationView
  def view_template
    div(class: "space-y-6") do
      h1(class: "text-3xl") { "Comparing components" }
      div(class: "space-y-16") do
        h2(class: "text-xl") { "Stimulus Greeter Examples" }
        section(class: "space-y-8") do
          h3(class: "text-md font-bold") { "A plain old Phlex::HTML" }
          code(class: "block bg-gray-100") do
            %(render ::GreeterComponent.new(cta: "Greet w. Phlex::HTML"))
          end
          render TypedPhlex::GreeterComponent.new(cta: "Greet w. Phlex::HTML")
          h3(class: "text-md font-bold") { "A Phlex::HTML with Vident" }
          code(class: "block bg-gray-100") do
            %(render ::GreeterVidentComponent.new(cta: "Greet w. Vident + Phlex::HTML"))
          end
          render TypedPhlex::GreeterVidentComponent.new(
            cta: "Greet w. Vident + Phlex::HTML"
          )
          h3(class: "text-md font-bold") do
            "An example of a component where we use Vident to set Stimulus actions/targets on other components (eg in a Phlex::HTML slot)"
          end
          pre do
            %(
<%= render ::GreeterWithTriggerComponent.new do |greeter| %>
  <% greeter.trigger(
     before_clicked_message: "I'm a button component!",
     after_clicked_message: "Greeted! Click me again to reset.",
     actions: [
       greeter.action(:click, :greet),
     ],
     html_options: {
       class: "bg-red-500 hover:bg-red-700"
     }
   ) %>
<% end %>
)
          end
          render TypedPhlex::GreeterWithTriggerComponent.new do |greeter|
            greeter.trigger(
              before_clicked_message: "I'm a button component!",
              after_clicked_message: "Greeted! Click me again to reset.",
              actions: [greeter.action(:click, :greet)],
              html_options: {
                class: "bg-red-500 hover:bg-red-700"
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
            div(class: "block") { render TypedPhlex::AvatarComponent.new(initials: "AB") }
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with a value of invalid type passed to attributes, will raise an error."
            end
            code(class: "block bg-gray-100") do
              %(render AvatarComponent.new(initials: 123, size: "foo"))
            end
            div(class: "block") do
              render TypedPhlex::AvatarComponent.new(initials: 123, size: "foo")
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
              render TypedPhlex::AvatarComponent.new(
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
              render TypedPhlex::AvatarComponent.new(
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
              %(render AvatarComponent.new(url: "https://i.pravatar.cc/300", initials: "AB", html_options: {alt: "My alt text", class: "ring-2 ring-red-900"}))
            end
            div(class: "block") do
              render TypedPhlex::AvatarComponent.new(
                url: "https://i.pravatar.cc/300",
                initials: "AB",
                html_options: {
                  alt: "My alt text",
                  class: "ring-2 ring-red-900"
                }
              )
            end
          end
          div(class: "space-y-6") do
            h3(class: "text-md font-bold") do
              "with initials and small size and border"
            end
            div(class: "block") do
              render TypedPhlex::AvatarComponent.new(
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
              %(render AvatarComponent.new(initials: "SG", shape: :square, html_options: {class: "border-2 border-red-600"}))
            end
            div(class: "block") do
              render TypedPhlex::AvatarComponent.new(
                initials: "SG",
                shape: :square,
                html_options: {
                  class: "border-2 border-red-600"
                }
              )
            end
          end
        end
      end
    end
  end
end
