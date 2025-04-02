class ApplicationController < ActionController::Base
  layout -> { ApplicationLayout }

  def index
    render ApplicationIndexView.new
  end
end
