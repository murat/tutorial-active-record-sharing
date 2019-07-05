require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem "models", path: "../models"
  gem "activerecord"
  gem "sqlite3", "~> 1.4"
end

require 'active_record'
require 'models'

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "../database/app.sqlite3"
)

puts 'Gems installed and loaded!'
puts "Total student: #{Models::Student.count}"

Models::Student.create id: Models::Student.order(id: :desc).limit(1).first.id + 1, name: "murat"
puts "Total student: #{Models::Student.count}"
