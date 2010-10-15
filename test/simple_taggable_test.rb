require File.dirname(__FILE__) + '/test_helper'

class SimpleTaggableTest < Test::Unit::TestCase
  def setup
    DatabaseCleaner.start
    load File.expand_path('../fixtures.rb', __FILE__)
  end

  fixtures = {
    'User'  => ['john', 'jane'],
    'Photo' => ['big_dog', 'small_dog', 'bad_cat', 'flower', 'sky'],
    'Post'  => ['rain', 'ground']
  }

  fixtures.each do |model, names|
    names.each do |name|
      class_eval <<-rb
        def #{name}
          @#{name} ||= #{model}.find_by_name(#{name.gsub('_', ' ').inspect})
        end
      rb
    end
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

  test 'taggable.tags.with_counts' do
    assert_tag_counts small_dog.tags.with_counts, :great => 2, :nature => 3, :animal => 3
  end

  # test 'tag_counts on association with options' do
  #   assert_equal [], @john.posts.tags.with_counts(:conditions => '1 = 0')
  #   assert_tag_counts @john.posts.tags.with_counts(:at_most => 2), :great => 1, :sucks => 1
  # end
  #
  # test 'tag_counts on has_many :through' do
  #   assert_tag_counts @john.magazines.tags.with_counts789, :great => 1
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
    assert_equal [], Photo.tagged(nil)
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

  test '#tagged with association scope' do
    assert_equal [flower, sky], jane.photos.tagged('nature')
    assert_equal [small_dog], john.photos.tagged('nature')
    assert_equal [], john.photos.tagged('nature', :except => 'animal')
    assert_equal [], john.photos.tagged('nature bad', :match_all => true)
  end

  test "#tagged with sti" do
    photo = SpecialPhoto.create!(:name => "Foo", :tag_list => "STI")
    assert_equal [photo], SpecialPhoto.tagged("STI")
    assert Photo.tagged("STI").map(&:id).include?(photo.id)
  end
  
  test '#save_tags saves new tags' do
    small_dog.tag_list.add('new')
    small_dog.save
    assert Tag.find_by_name('new')
    assert_equal %w(animal nature great new), small_dog.reload.tag_list
  end
  
  test '#save_tags removes old tags' do
    small_dog.tag_list.remove('great')
    small_dog.save
    assert_equal %w(animal nature), small_dog.reload.tag_list
  end
  
  test 'unused tags are deleted by default' do
    tag_count = Tag.count
    bad_cat.tag_list.remove('crazy animal')
    bad_cat.save!
    assert_equal tag_count - 1, Tag.count
  end
  
  test 'unused tags are not deleted when Tag.destroy_unused is set to false' do
    tag_count = Tag.count
    Tag.destroy_unused = false
    big_dog.tag_list.remove('animal')
    assert_equal tag_count, Tag.count
  end
  
  test '#tag_list reader returns a tag list' do
    assert_equivalent ['sucks', 'crazy animal', 'animal'], bad_cat.tag_list
  end
  
  test 'adding new tags via #tag_list writer' do
    assert_equivalent %w(nature), sky.tag_list
    sky.update_attributes!(:tag_list => "#{sky.tag_list} one two")
    assert_equivalent %w(nature one two), sky.tag_list
  end
  
  test 'removing tags via #tag_list writer' do
    assert_equivalent %w(nature), sky.tag_list
    sky.update_attributes!(:tag_list => "")
    assert_equivalent [], sky.tag_list
  end
  
  test 'tag_list reader on a new record works' do
    photo = Photo.new(:name => 'test')
    assert photo.tag_list.blank?
    photo.tag_list = "one, two"
    assert_equal "one, two", photo.tag_list.to_s
  end
  
  test 'tag_list writer clears tag_list with nil' do
    assert small_dog.tag_list.present?
    assert small_dog.update_attributes(:tag_list => nil)
    assert small_dog.reload.cached_tag_list.blank?
    assert small_dog.reload.tag_list.blank?
  end
  
  test 'tag_list writer clears tag_list with a string containing whitespace' do
    assert small_dog.tag_list.present?
    assert small_dog.update_attributes(:tag_list => '  ')
    assert small_dog.tag_list.blank?
    assert small_dog.reload.tag_list.blank?
  end
  
  test 'tag_list is being reset on reload' do
    assert small_dog.tag_list.present?
    small_dog.tag_list = nil
    assert small_dog.tag_list.blank?
    assert small_dog.reload.tag_list.present?
  end
  
  test '#tag_list= overwrites tags (i.e. changes the case of existing tags)' do
    small_dog.update_attributes!(:tag_list => small_dog.tag_list.to_s.titleize)
    assert_equal 'Animal Nature Great', small_dog.reload.tag_list.to_s
  end
  
  test 'case insensivity' do
    tag_count = Tag.count
  
    Photo.create!(:name => "Foo", :tag_list => "baz")
    Photo.create!(:name => "Bar", :tag_list => "Baz")
    Photo.create!(:name => "Bar", :tag_list => "BAZ")
  
    assert_equal tag_count + 1, Tag.count
    assert_equal Photo.tagged("baz").map(&:name), Photo.tagged("BAZ").map(&:name)
  end
  
  test 'caches the tag_list before save' do
    assert_equal 'animal nature great', small_dog.cached_tag_list
    small_dog.update_attributes(:tag_list => 'Foo')
    assert_equal 'Foo', small_dog.cached_tag_list
    assert_equal 'Foo', small_dog.reload.cached_tag_list
  end
  
  test 'cached_tag_list used' do
    assert_equal 'animal nature great', small_dog.cached_tag_list
    small_dog.reload
    assert_no_queries { assert_equal %w(animal nature great), small_dog.tag_list }
  end
end
