require File.dirname(__FILE__) + '/test_helper'

class SimpleTaggableTest < Test::Unit::TestCase
  def setup
    DatabaseCleaner.start
    load Pathname.local('fixtures.rb')
  end

  { User  => ['john', 'jane'], Photo => ['big dog', 'small dog', 'bad cat', 'flower', 'sky'], Post  => ['rain', 'ground'] }.each do |model, names|
    names.each { |name| define_method(name.gsub(' ', '_')) { model.find_by_name(name) } }
  end
  
  test "Taggable.tags looks up tags" do
    assert Photo.tags.first.is_a?(Tag)
  end
  
  test "model.association.tags looks up tags tagging associated objects" do
    assert john.posts.tags.all? { |tag| tag.is_a?(Tag) }
  
    tag_names = jane.posts.map { |post| post.tags }.flatten.map(&:name).uniq.sort
    assert_equal tag_names, jane.posts.tags.map(&:name).sort
  end
  
  test 'Taggable.tags eager loads tag counts' do
    Photo.tags.first.is_a?(Tag)
    assert_tag_counts Photo.tags, :great => 2, :sucks => 1, :nature => 3, :'crazy animal' => 1, :animal => 3
    assert_tag_counts Post.tags,  :great => 2, :sucks => 2, :nature => 7
  end
  
  test 'Taggable.tags with :at_least' do
    assert_tag_counts Photo.tags(:at_least => 2), :great => 2, :animal => 3, :nature => 3
  end
  
  test 'Taggable.tags with :at_most' do
    assert_tag_counts Photo.tags(:at_most => 1), :sucks => 1, :'crazy animal' => 1
  end
  
  test 'Taggable.tags.take' do
    assert_tag_counts Photo.tags.take(1), :great => 2
  end

  test 'Taggable.tags with :at_least and where' do
    assert_tag_counts Photo.tags(:at_least => 2).where("tags.name LIKE '%i%'"), :animal => 3
  end
  
  test 'Taggable.tags with order and limit' do
    assert_equal %w(nature great), Post.tags.limit(2).order('count DESC, name').map(&:name)
  end
  
  test 'model.association.tags' do
    assert_tag_counts john.posts.tags, :great => 1, :nature => 5, :sucks => 1
    assert_tag_counts jane.posts.tags, :great => 1, :nature => 2, :sucks => 1
  
    assert_tag_counts john.photos.tags, :great => 1, :sucks => 1, :'crazy animal' => 1, :animal => 3, :nature => 1
    assert_tag_counts jane.photos.tags, :nature => 2, :great => 1
  end
  
  # test 'taggable.tags' do
  #   assert_tag_counts small_dog.tag_counts, :great => 2, :nature => 3, :animal => 3
  # end
  
  # test 'tag_counts on association with options' do
  #   assert_equal [], @john.posts.tag_counts(:conditions => '1 = 0')
  #   assert_tag_counts @john.posts.tag_counts(:at_most => 2), :great => 1, :sucks => 1
  # end
  #
  # test 'tag_counts on has_many :through' do
  #   assert_tag_counts @john.magazines.tag_counts, :great => 1
  # end
  
  test '#tag_list' do
    assert_equal %w(animal nature great), small_dog.tag_list
  end
  
  test '#tagged finds records tagged with the given tags' do
    assert_equal [small_dog, big_dog, bad_cat], Photo.tagged('animal')
    assert_equal [bad_cat], Photo.tagged('"crazy animal"')
    assert_equal [rain, ground], Post.tagged('sucks')
  end
  
  test '#tagged does not find records tagged with nothing or blank tags' do
    assert_equal [], Photo.tagged("")
    assert_equal [], Photo.tagged([])
  end
  
  test '#tagged does not find records tagged with non existant tags' do
    assert_equal [], Post.tagged('doesnotexist')
    assert_equal [], Photo.tagged(['doesnotexist'])
    assert_equal [], Photo.tagged([Tag.new(:name => 'unsaved tag')])
  end
  
  test '#tagged finds records tagged with at least one of the given tags' do
    assert_equal [small_dog, big_dog, bad_cat, flower], Photo.tagged(['animal', 'great'])
  end
  
  test '#tagged finds records tagged with all of the given tags when :match_all option was set' do
    assert_equal [small_dog], Photo.tagged('animal great', :match_all => true)
  end
  
  test '#tagged using match_all and includes' do
    photo = Photo.tagged(['great', 'animal'], :match_all => true).includes(:user).first
    assert_equal small_dog, photo
    assert_no_queries { photo.user }
  end
  
  test '#tagged using conditions' do
    assert_equal [], Photo.tagged('great nature').where('1 = 0')
  end
  
  test '#tagged using :except option' do
    assert_equal [flower, sky], Photo.tagged('nature', :except => 'animal')
  end
  
  # test '#tagged with association scope' do
  #   assert_equal [@flower, @sky], @jane.photos.tagged('Nature')
  #   assert_equal [@small_dog], @john.photos.tagged('Nature')
  #   assert_equal [], @john.photos.tagged('Nature', :except => 'Animal')
  #   assert_equal [], @john.photos.tagged('Nature Bad', :match_all => true)
  # end
  #
  # test '#save_tags saves new tags' do
  #   @small_dog.tag_list.add('New')
  #   @small_dog.save
  #   assert Tag.find_by_name('New')
  #   assert_equal %w(Nature Animal Great New), @small_dog.reload.tag_list
  # end
  #
  # test '#save_tags removes old tags' do
  #   @small_dog.tag_list.remove('Great')
  #   @small_dog.save
  #   assert_equal %w(Nature Animal), @small_dog.reload.tag_list
  # end
  #
  # test 'unused tags are deleted by default' do
  #   assert_difference('Tag.count', -1) do
  #     @bad_cat.tag_list.remove('Crazy Animal')
  #     @bad_cat.save!
  #   end
  # end
  #
  # test 'unused tags are not deleted when Tag.destroy_unused is set to false' do
  #   Tag.destroy_unused = false
  #   assert_no_difference('Tag.count') do
  #     @big_dog.tag_list.remove('Animal')
  #     @big_dog.save!
  #   end
  # end
  #
  # test '#tag_list reader returns a tag list' do
  #   assert_equivalent ['Sucks', 'Crazy Animal', 'Animal'], @bad_cat.tag_list
  # end
  #
  # test 'adding new tags via #tag_list writer' do
  #   assert_equivalent %w(Nature), @sky.tag_list
  #   @sky.update_attributes!(:tag_list => "#{@sky.tag_list} One Two")
  #   assert_equivalent %w(Nature One Two), @sky.tag_list
  # end
  #
  # test 'removing tags via #tag_list writer' do
  #   assert_equivalent %w(Nature), @sky.tag_list
  #   @sky.update_attributes!(:tag_list => "")
  #   assert_equivalent [], @sky.tag_list
  # end
  #
  # test 'tag_list reader on a new record' do
  #   photo = Post.new(:text => 'Test')
  #   assert photo.tag_list.blank?
  #   photo.tag_list = "One, Two"
  #   assert_equal "One, Two", photo.tag_list.to_s
  # end
  #
  # test 'tag_list writer clears tag_list with nil' do
  #   photo = @small_dog
  #   assert !photo.tag_list.blank?
  #   assert photo.update_attributes(:tag_list => nil)
  #   assert photo.tag_list.blank?
  #   assert photo.reload.tag_list.blank?
  # end
  #
  # test 'tag_list writer clears tag_list with a string containing only spaces' do
  #   photo = @small_dog
  #   assert !photo.tag_list.blank?
  #   assert photo.update_attributes(:tag_list => '  ')
  #   assert photo.tag_list.blank?
  #   assert photo.reload.tag_list.blank?
  # end
  #
  # test 'tag_list is reset on reload' do
  #   photo = @small_dog
  #   assert !photo.tag_list.blank?
  #   photo.tag_list = nil
  #   assert photo.tag_list.blank?
  #   assert !photo.reload.tag_list.blank?
  # end
  #
  # test 'changing the case of tags via #tag_list writer' do
  #   @small_dog.update_attributes!(:tag_list => @small_dog.tag_list.to_s.upcase)
  #   assert_equal 'NATURE ANIMAL GREAT', @small_dog.reload.tag_list.to_s
  # end
  #
  # test 'case insensivity' do
  #   assert_difference "Tag.count", 1 do
  #     Photo.create!(:title => "Foo", :tag_list => "baz")
  #     Photo.create!(:title => "Bar", :tag_list => "Baz")
  #     Photo.create!(:title => "Bar", :tag_list => "BAZ")
  #   end
  #
  #   assert_equal Photo.tagged("baz"), Photo.tagged("BAZ")
  # end
  #
  # test "tagged scope works with sti" do
  #   photo = SpecialPhoto.create!(:title => "Foo", :tag_list => "STI")
  #   assert_equal [photo], SpecialPhoto.tagged("STI")
  #   assert Photo.tagged("STI").map(&:id).include?(photo.id)
  # end
  #
  # test 'caches the tag_list before save' do
  #   assert @small_dog.cached_tag_list.nil?
  #   @small_dog.save!
  #   assert_equal 'Nature Animal Great', @small_dog.cached_tag_list
  #
  #   @small_dog.update_attributes(:tag_list => 'Foo')
  #   assert_equal 'Foo', @small_dog.cached_tag_list
  #   assert_equal 'Foo', @small_dog.reload.cached_tag_list
  # end
  #
  # test 'cached_tag_list used' do
  #   @small_dog.save!
  #   @small_dog.reload
  #   assert_no_queries { assert_equal %w(Nature Animal Great), @small_dog.tag_list }
  # end
end