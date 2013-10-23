require 'has_many_polymorphs/active_record/base'
require 'has_many_polymorphs/active_record/associations'
require 'has_many_polymorphs/active_record/associations/builder/has_many_polymorphs'
require 'has_many_polymorphs/active_record/associations/polymorphic_association_scope'
require 'has_many_polymorphs/active_record/reflection'

module HasManyPolymorphs

  module Base
    extend ActiveSupport::Concern

    module ClassMethods
      def has_many_polymorphs(association_id, options = {}, &extension)
        scope = nil #we are not going to use any scope with has_many_polymorphs
        ActiveRecord::Associations::Builder::HasManyPolymorphs.build(self, association_id, options, scope, &extension)
      end
    end
  end
end
