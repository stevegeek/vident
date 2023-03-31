# frozen-string-literal: true

class ApplicationIndexView < ApplicationView
  def template
    div do
      render AvatarComponent.new(initials: "J S", size: :large)
    end
    div do
      p { "The next avatar component won't render!" }
      begin
        render AvatarComponent.new(initials: 23, size: :foo)
      rescue => e
        plain "Yay rescued the error! #{e.class}: #{e.message}"
      end
    end
  end
end
