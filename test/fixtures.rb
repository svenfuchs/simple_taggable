great  = Tag.create! :name => 'great'
sucks  = Tag.create! :name => 'sucks'
nature = Tag.create! :name => 'nature'
animal = Tag.create! :name => 'animal'
crazy  = Tag.create! :name => 'crazy animal'
       
john   = User.create! :name => 'john'
jane   = User.create! :name => 'jane'

ruby   = Magazine.create! :name => 'ruby', :tag_list => 'great'

Photo.create! :user => john, :name => 'small dog', :tag_list => 'animal nature great'
Photo.create! :user => john, :name => 'big dog',   :tag_list => 'animal'
Photo.create! :user => john, :name => 'bad cat',   :tag_list => 'animal "crazy animal" sucks'
Photo.create! :user => jane, :name => 'flower',    :tag_list => 'nature great'
Photo.create! :user => jane, :name => 'sky',       :tag_list => 'nature'

Post.create!  :user => john, :name => 'blue sky',  :tag_list => 'great nature'
Post.create!  :user => john, :name => 'grass',     :tag_list => 'nature'
Post.create!  :user => john, :name => 'rain',      :tag_list => 'sucks nature'
Post.create!  :user => john, :name => 'cloudy',    :tag_list => 'nature'
Post.create!  :user => john, :name => 'still',     :tag_list => 'nature'
Post.create!  :user => jane, :name => 'ground',    :tag_list => 'nature sucks'
Post.create!  :user => jane, :name => 'flowers',   :tag_list => 'nature great'

Subscription.create :user => john, :magazine => ruby