# frozen_string_literal: true

module Vident
  # Include rake tasks
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/vident.rake"
    end
  end
end
