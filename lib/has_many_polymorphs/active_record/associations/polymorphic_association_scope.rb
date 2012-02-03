module ActiveRecord
  module Associations
    class PolymorphicAssociationScope < AssociationScope
      def add_constraints(scope)
        scope.joins(construct_joins).where(construct_conditions)
      end

      private

      def construct_from #:nodoc:
        # build the FROM part of the query, in this case, the polymorphic join table
        @association.reflection.klass.quoted_table_name
      end

      def construct_owner #:nodoc:
        # the table name for the owner object's class
        owner.class.quoted_table_name
      end

      def construct_owner_key #:nodoc:
        # the primary key field for the owner object
        owner.class.primary_key
      end

      def construct_joins(custom_joins = nil) #:nodoc:
        # build the string of default joins
        "JOIN #{construct_owner} AS polymorphic_parent " +
          "ON #{construct_from}.#{options[:foreign_key]} = " +
            "polymorphic_parent.#{construct_owner_key} " +
        options[:from].map do |plural|
          klass = plural._as_class
          join =
            "LEFT JOIN #{klass.quoted_table_name} " +
            "ON #{construct_from}.#{options[:polymorphic_key]} = " +
              "#{klass.quoted_table_name}.#{klass.primary_key} " +
            "AND #{construct_from}.#{options[:polymorphic_type_key]} = " +
              "#{@association.reflection.klass.quote_value(klass.base_class.name)}"

            unless (conditions = default_where(klass)).blank?
              join += " AND #{conditions}"
            end

            join
        end.uniq.join(" ")
      end

      # get where values from models' default scopes
      # and build sql
      def default_where(klass)
        sql          = ''
        arel_nodes   = klass.scoped.with_default_scope.where_values.grep(Arel::Nodes::Equality)
        string_nodes = klass.scoped.with_default_scope.where_values.grep(String)

        unless arel_nodes.empty?
          sql += arel_nodes.inject(arel_nodes[0]) do |arel, equality|
            arel = arel.and(equality); arel
          end.to_sql
        end

        unless string_nodes.empty?
          sql += ' AND ' + string_nodes.map { |node| "(#{node})"}.join(' AND ')
        end

        sql
      end

      def construct_quoted_owner_attributes(*args) #:nodoc:
        # no access to returning() here? why not?
        type_key = options[:foreign_type_key]
        h = { options[:foreign_key] => owner.id }
        h[type_key] = owner.class.base_class.name if type_key
        h
      end

      def construct_conditions #:nodoc:
        # build the fully realized condition string
        conditions = construct_quoted_owner_attributes.map do |field, value|
          "#{construct_from}.#{field} = #{@association.reflection.klass.quote_value(value)}" if value
        end
        "(" + conditions.compact.join(') AND (') + ")"
      end
    end
  end
end
