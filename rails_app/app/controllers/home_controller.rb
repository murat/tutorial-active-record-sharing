class HomeController < ApplicationController
  def index
    render json: { students: Models::Student.all }
  end
end
