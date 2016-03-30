module JsonbAttributeHelpers
  extend ActiveSupport::Concern

  include JsonbTypeHelper

  class_methods do
    def jsonb_attr_helper(jsonb_attribute, attributes_hash)
      _create_dirty_methods

      # source: jsonb_accessor
      # this gem is overall terrible for performance but..
      # some of the code is very helpful for scopes and queries
      # Copyright (c) 2015 Michael Crismali
      jsonb_attribute_scope_name = "#{jsonb_attribute}_contains"
      _create_jsonb_attribute_scope_name(jsonb_attribute, jsonb_attribute_scope_name)
      __create_jsonb_standard_scopes(attributes_hash, jsonb_attribute_scope_name)
      __create_jsonb_typed_scopes(jsonb_attribute, attributes_hash)

    end

    def _create_dirty_methods
      stored_attributes.each do |store, keys|
        keys.each do |key|
          define_method :"#{key}_changed?" do
            changes[store] && changes[store].map { |v| v.try(:[], key) }.uniq.length > 1
          end
        end
      end
    end

    def __create_jsonb_standard_scopes(attributes_hash, jsonb_attribute_scope_name)
      attributes_hash.keys.each do |field|
        scope "with_#{field}", -> (value) { send(jsonb_attribute_scope_name, field => value) }
      end
    end

    def _create_jsonb_attribute_scope_name(jsonb_attribute, jsonb_attribute_scope_name)
      scope jsonb_attribute_scope_name, (lambda do |attributes|
                                           query_options = new(attributes).send(jsonb_attribute)
                                           fields = attributes.keys.map(&:to_s)
                                           query_options.delete_if { |key, value| fields.exclude?(key) }
                                           query_json = JsonbTypeHelper.type_cast_as_jsonb(query_options)
                                           where("#{table_name}.#{jsonb_attribute} @> ?", query_json)
                                         end)
    end

    def __create_jsonb_typed_scopes(jsonb_attribute, attributes_hash)
      attributes_hash.each do |field, type|
        case type
        when :boolean
          ___create_jsonb_boolean_scopes(field)
        when :integer, :float, :decimal, :big_integer
          ___create_jsonb_numeric_scopes(field, jsonb_attribute, type)
        when :date_time, :date
          ___create_jsonb_date_time_scopes(field, jsonb_attribute, type)
        when /array/
          ___create_jsonb_array_scopes(field)
        end
      end
    end

    def ___create_jsonb_boolean_scopes(field)
      scope "is_#{field}", -> { send("with_#{field}", true) }
      scope "not_#{field}", -> { send("with_#{field}", false) }
    end

    def ___create_jsonb_numeric_scopes(field, jsonb_attribute, type)
      safe_type = type.to_s.gsub("big_", "")
      scope "__numeric_#{field}_comparator", -> (value, operator) { where("((#{table_name}.#{jsonb_attribute}) ->> ?)::#{safe_type} #{operator} ?", field, value) }
      scope "#{field}_lt", -> (value) { send("__numeric_#{field}_comparator", value, "<") }
      scope "#{field}_lte", -> (value) { send("__numeric_#{field}_comparator", value, "<=") }
      scope "#{field}_gte", -> (value) { send("__numeric_#{field}_comparator", value, ">=") }
      scope "#{field}_gt", -> (value) { send("__numeric_#{field}_comparator", value, ">") }
    end

    def ___create_jsonb_date_time_scopes(field, jsonb_attribute, type)
      scope "__date_time_#{field}_comparator", -> (value, operator) { where("((#{table_name}.#{jsonb_attribute}) ->> ?)::timestamp #{operator} ?::timestamp", field, value.to_json) }
      scope "#{field}_before", -> (value) { send("__date_time_#{field}_comparator", value, "<") }
      scope "#{field}_after", -> (value) { send("__date_time_#{field}_comparator", value, ">") }
    end

    def ___create_jsonb_array_scopes(field)
      scope "#{field}_contains", -> (value) { send("with_#{field}", [value]) }
    end
  end
end
