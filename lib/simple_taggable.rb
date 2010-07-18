require 'simple_taggable/act_macro'
require 'simple_taggable/class_methods'
require 'simple_taggable/instance_methods'
require 'simple_taggable/tag'
require 'simple_taggable/tagging'
require 'simple_taggable/tag_list'

ActiveRecord::Base.send(:extend, SimpleTaggable::ActMacro)
