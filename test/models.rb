config = { 'adapter' => 'sqlite3', 'database' => ':memory:' }
ActiveRecord::Base.configurations = { 'test' =>  config }
ActiveRecord::Base.establish_connection(config)

ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define :version => 0 do
  create_table :magazines, :force => true do |t|
    t.string :name
    t.string :cached_tag_list
  end
  
  create_table :posts, :force => true do |t|
    t.references :user
    t.string :name
    t.string :type
    t.string :cached_tag_list
  end
  
  create_table :photos, :force => true do |t|
    t.references :user
    t.string :name
    t.string :cached_tag_list
  end
  
  create_table :subscriptions, :force => true do |t|
    t.references :user
    t.references :magazine
  end
  
  create_table :tags, :force => true do |t|
    t.string :name
  end
  
  create_table :taggings, :force => true do |t|
    t.references :tag
    t.references :taggable
    t.string :taggable_type
    t.timestamps :created_at, :datetime
  end
  
  create_table :users, :force => true do |t|
    t.string :name
  end
end

class Magazine < ActiveRecord::Base
  acts_as_taggable
end

class Photo < ActiveRecord::Base
  acts_as_taggable
  belongs_to :user
end

class SpecialPhoto < Photo
end

class Post < ActiveRecord::Base
  acts_as_taggable
  belongs_to :user
end

class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :magazine
end

class User < ActiveRecord::Base
  has_many :posts
  has_many :photos
  has_many :subscriptions
  has_many :magazines, :through => :subscriptions
end