# frozen-string-literal: true

class ApplicationIndexView < ApplicationView
  def template
    render AvatarComponent.new(initials: "J S")
  end
end
