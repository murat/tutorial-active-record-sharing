# ActiveRecord modellerini projeler arası paylaştırmak

Günümüzde microservis, dağıtık uygulamar.. vs popüler olmaktan ziyade, otomatik ölçeklenen uygulamalar geliştirmek için gerekli bir yaklaşım halini aldı. Geliştirdiğimiz uygulamanın farklı görevleri olan kısımlarını farklı uygulamalar olarak dağıtabilmek için projeleri bölmeye başladık. Ben de böyle bir ihtiyaçtan yola çıkıp kompleks bir yapısı olan ve refactor gerektiren bir rails uygulamasını görevlerine göre ufak uygulamacıklara bölmeye başladım. Bunu yaparken en önemli sorunum kod kopyalamadan(duplicate) etmeden bu işin altından nasıl kalkarım, daha güzel bir deyişle data modelimi birden fazla rails ve ya rails olmayan projeler arasında nasıl paylaştırırım sorusuna odaklandım. Denemelerim sonucunda sadece ActiveRecord sınıflarını taşıyan bir ruby gem'i yaparak, bu gem'i bir rails projesi, bir sinatra projesi, bir de saf ruby betiği ile kullanabilir hale getirdim. Bu yazıda bulgularımı bir rehber niteliğinde paylaşmak istiyorum.

## İçerik

- [ActiveRecord sınıflarını taşıyan bir ruby gem'i](#activerecord-sınıflarını-taşıyan-bir-ruby-gemi)
- [Veritabanı oluşturalım](#veritabanı-oluşturalım)
- [Saf ruby betiklerinde nasıl kullanırım?](#saf-ruby-betiklerinde-nasıl-kullanırım)
  - [Satır içi bundle](#satır-içi-bundle)
- [Sinatra](#sinatra)
- [Rails](#rails)
- [Son](#son)

## ActiveRecord sınıflarını taşıyan bir ruby gem'i

Yeni bir ruby gem'i oluşturmak için bundle bize aşağıdaki gibi bir template veriyor.

```bash
➜ bundle gem models
...
  create  models/Gemfile
  create  models/lib/models.rb
  create  models/lib/models/version.rb
  create  models/models.gemspec
  create  models/Rakefile
  create  models/README.md
  create  models/bin/console
  create  models/bin/setup
  create  models/.gitignore
  create  models/.travis.yml
  create  models/.rspec
  create  models/spec/spec_helper.rb
  create  models/spec/models_spec.rb
  create  models/LICENSE.txt
  create  models/CODE_OF_CONDUCT.md
```

```bash
# :)
➜ mv models models_rb
```

Tüm uygulama kodlarımızı **lib** dizini içinde yazacağız. Örnek olarak **Student** adında bir ActiveRecord modeli oluşturup diğer projelerimizde bunu kullanacağız. Öncelikle .gemspec dosyasında gerekli satırları düzenledikten sonra Gemfile'a 'activerecord' gem'ini ekliyoruz.

```ruby
# Gemfile

source "https://rubygems.org"

gem "activerecord", "~> 5.0"

# Specify your gem's dependencies in models.gemspec
gemspec
```

`lib/models` dizini altında da Student sınıfını oluşturup `lib/models.rb` dosyasında `require` ederek gem'i paketleyebiliriz.

```ruby
# lib/models/student.rb
require "active_record"

module Models
  class Student < ActiveRecord::Base; end
end
```

```ruby
# lib/models.rb
require "models/version"
require "models/student"

module Models
  class Error < StandardError; end
end
```

Gem'i paketleyip rubygems'de yayınlamak isterseniz gerekli adımları [şuradan](https://guides.rubygems.org/publishing/) öğrenebilirsiniz. Biz şimdilik yerel adres üzerinden diğer projelerimize dahil edeceğiz. Fakat .gemspec dosyamızdaki `spec.files` değeri `git ls-files -z` komutundan dönen dosyaları `LOAD_PATH` e dahil ettiği için `git add .` ve `git commit -m "mesaj"` komutlarını çalıştırmak gerekiyor.

## Veritabanı oluşturalım

Basit bir örnek olacağı için sqlite3 ile bir veritabanı oluşturacağım. Bunun için `database` adında bir dizin açarak içinde `sqlite3 app.sqlite3` komutunu çalıştırıyorum ve aşağıdaki sql ile students tablosunu oluşturuyorum.

```sql
CREATE TABLE students(
  id INT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL
);
```

Tablo oluşturduktan sonra kontrol amaçlı `.tables` komutunu çalıştırıyor ve tablo göründüyse `.quit` komutu ile çıkıyorum.

## Saf ruby betiklerinde nasıl kullanırım?

Başka bir dizine giderek bir `app.rb` dosyası oluşturalım.

### Satır içi bundle

Bir projeye `bundle` edilmiş bir gem'i dahil etmek için ilk akla gelen yöntem `bundle init` diyerek bir `Gemfile` oluşturmak olabilir ama bu sadece bir dosyalık betik olacağından yeni öğrendiğim [`bundler/inline`](https://bundler.io/v2.0/guides/bundler_in_a_single_file_ruby_script.html) kullanarak devam edeceğim. Bu işimizi çok kolaylıştıracak. `app.rb` dosyasına aşağıdakileri ekleyelim.

```ruby
# app.rb
require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem "models", path: "../models_rb"
  gem "activerecord"
  gem "sqlite3", "~> 1.4"
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: "../database/app.sqlite3"
)

puts 'Gems installed and loaded!'
puts "Total student: #{Models::Student.count}"

Models::Student.create id: Models::Student.order(id: :desc).limit(1).first.id + 1, name: "murat"
puts "Total student: #{Models::Student.count}"
```

Ve ruby dosyamızı `ruby app.rb` komutu ile çalıştırabiliriz. Göreceğiniz üzere ActiveRecord modelimiz saf bir ruby betiğinde kullanılabilir halde.

Not: Gerçek hayatta veritabanımızı düzgün oluşturacağımız id değerini biz vermeyeceğiz.

## Sinatra

Basit bir sinatra projesi oluşturalım.

```bash
➜ cd .. && mkdir sinatra_app && cd sinatra_app
➜ bundle init
Writing new Gemfile to sinatra_app/Gemfile
```

Gemfile'a aşağıdakileri ekleyip `bundle install` çalıştıralım.

```ruby
# Gemfile

gem "models", path: "../models_rb"
gem "sinatra"
gem 'sinatra-activerecord'
gem "rake"
gem "json"
gem "sqlite3", "~> 1.4"
```

Ve app.rb adında bir dosya açıp aşağıdakileri ekleyelim.

```ruby
# app.rb
require "sinatra"
require "sinatra/activerecord"
require "json"
require "models"

set :database, {adapter: "sqlite3", database: "../database/app.sqlite3"}

get "/" do
  content_type :json
  Models::Student.all.to_json
end
```

Ve aşağıdaki şekilde çalıştıralım,

```bash
➜ bundle exec ruby app.rb
```

Şimdi tarayıcımızdan [`http://localhost:4567`](http://localhost:4567) adresine gittiğimizde veritabanına eklediğimiz öğrencileri json olarak göreceğiz.

## Rails

Bir rails uygulaması oluşturalım, pratik olsun diye `--api` flag'i ile oluşturacağım.

```bash
➜ cd .. && rails new rails_app --api -B -T

➜ cd rails_app
```

Gemfile'a `models` gem'imimizi ekleyelim

```ruby
# Gemfile
# ...
gem "models", path: "../models_rb"
```

`bundle install` komutunu çalıştırıp `home/index` diye bir rota oluşturalım.

```bash
➜ rails g controller home index
```

`home_controller` `index` metoduna aşağıdakini yazalım.

```ruby
# home_controller.rb

# ...
  def index
    render json: { students: Models::Student.all }
  end
end
```

Ve son olarak `database.yml`'da sqlite database adresimizi güncelleyip `rails s` komutu ile sunucusunu ayağa kaldıralım. Ve tarayıcımızdan [`http://localhost:3000/home/index`](http://localhost:3000/home/index) adresine gidip öğrencilere bakalım.

## Son

Artık `models` gibi bir gem geliştirip tüm ActiveRecord sınıflarımızı yazarak, birden fazla, farklı tipte uygulamada ortak akıl kullanabilir olduk. Faydalı olması dileğiyle.
