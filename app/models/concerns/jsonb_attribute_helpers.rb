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
      jsonb_attribute_initialization_method_name = "initialize_jsonb_attrs_for_#{jsonb_attribute}"

      klass = self
      define_attributes_and_data_types(klass, attributes_hash)
      define_typed_accessors(klass, attributes_hash)
      _initialize_jsonb_attrs(jsonb_attribute, attributes_hash, jsonb_attribute_initialization_method_name)
      _create_jsonb_attribute_scope_name(jsonb_attribute, jsonb_attribute_scope_name)
      __create_jsonb_standard_scopes(attributes_hash, jsonb_attribute_scope_name)
      __create_jsonb_typed_scopes(jsonb_attribute, attributes_hash)
      _create_jsonb_accessor_methods(jsonb_attribute, jsonb_attribute_initialization_method_name, attributes_hash)
    end

    def _initialize_jsonb_attrs(jsonb_attribute, attributes_hash, jsonb_attribute_initialization_method_name)
      define_method(jsonb_attribute_initialization_method_name) do
        t1 = Time.now.to_f
        if has_attribute?(jsonb_attribute)
          jsonb_attribute_hash = send(jsonb_attribute) || {}
          attributes_hash.keys.each do |field|
            send("#{field}=", jsonb_attribute_hash[field.to_s])
          end
        end
        t2 = Time.now.to_f
        puts (t2-t1) * 1000.0
      end

      after_initialize(jsonb_attribute_initialization_method_name)
    end

    def define_attributes_and_data_types(klass, attributes_hash)
      klass.send(:define_method, :attributes_and_data_types) do
        @attributes_and_data_types ||= attributes_hash.each_with_object({}) do |(name, type), attrs_and_data_types|
          t1 = Time.now.to_f
          attrs_and_data_types[name] = JsonbTypeHelper.fetch(type)
          t2 = Time.now.to_f
          puts "#{name}/#{type}: #{(t2-t1) * 1000.0}"
          attrs_and_data_types
        end
      end
    end

    def define_typed_accessors(klass, attributes_hash)
      klass.class_eval do
        attributes_hash.keys.each do |attribute_name|
          define_method(attribute_name) { attributes[attribute_name] }

          define_method("#{attribute_name}=") do |value|
            cast_value = attributes_and_data_types[attribute_name].type_cast_from_user(value)
            attributes[attribute_name] = cast_value
            # update_parent
          end
        end
      end
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

    def _create_jsonb_accessor_methods(jsonb_attribute, jsonb_attribute_initialization_method_name, attributes_hash)
      jsonb_accessor_methods = Module.new do
        define_method("#{jsonb_attribute}=") do |value|
          write_attribute(jsonb_attribute, value)
          send(jsonb_attribute_initialization_method_name)
        end

        define_method(:reload) do |*args, &block|
          super(*args, &block)
          send(jsonb_attribute_initialization_method_name)
          self
        end
      end

      __create_jsonb_typed_field_setters(jsonb_attribute, jsonb_accessor_methods, attributes_hash)
      include jsonb_accessor_methods
    end

    def __create_jsonb_typed_field_setters(jsonb_attribute, jsonb_accessor_methods, attributes_hash)
      attributes_hash.each do |field, type|
        attribute(field.to_s, JsonbTypeHelper.fetch(type))

        jsonb_accessor_methods.instance_eval do
          define_method("#{field}=") do |value, *args, &block|
            super(value, *args, &block)
            new_jsonb_value = (send(jsonb_attribute) || {}).merge(field => attributes[field.to_s])
            write_attribute(field, attributes[field.to_s])
          end
        end
      end
    end
  end
end
