class HomeController < ApplicationController
  def index
      @projects = Project.all
      @bugs = Bug.where(:user => current_user)
  end
end
