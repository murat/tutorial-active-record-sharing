require "sinatra"
require "json"
require "sinatra/activerecord"
require "models"

set :database, {adapter: "sqlite3", database: "../database/app.sqlite3"}

get "/" do
  content_type :json
  Models::Student.all.to_json
end
