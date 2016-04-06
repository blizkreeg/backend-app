# source: jsonb_accessor
# this gem is overall terrible for performance but..
# some of the code is very helpful for scopes and queries
# Copyright (c) 2015 Michael Crismali
# EDIT: using the gem again since pulling the accessors functionality would be too much duplication
CONSTANT_SEPARATOR = "::"
module JsonbTypeHelper
  ARRAY_MATCHER = /_array\z/
  UnknownType = Class.new(StandardError)

  class << self
    def fetch(type)
      case type
      when :array
        new_array(value)
      when ARRAY_MATCHER
        fetch_active_record_array_type(type)
      when :value
        value
      else
        fetch_active_record_type(type)
      end
    end

    def type_cast_as_jsonb(suspect)
      type_cast_hash = jsonb.type_cast_from_user(suspect)
      jsonb.type_cast_for_database(type_cast_hash)
    end

    private

    def jsonb
      @jsonb ||= fetch(:jsonb)
    end

    def fetch_active_record_array_type(type)
      subtype = type.to_s.sub(ARRAY_MATCHER, "")
      new_array(fetch_active_record_type(subtype))
    end

    def fetch_active_record_type(type)
      t1 = Time.now.to_f
      class_name = type.to_s.camelize
      t1 = Time.now.to_f
      klass = value_descendants.find do |ar_type|
        ar_type.to_s.split(CONSTANT_SEPARATOR).last == class_name
      end
      t2 = Time.now.to_f
      # puts "#{type}: #{(t2-t1) * 1000.0}"
      if klass
        klass.new
      else
        raise JsonbTypeHelper::UnknownType
      end
    end

    def value_descendants
      return @grouped_types unless @grouped_types.nil?
      grouped_types = ActiveRecord::Type::Value.descendants.group_by do |ar_type|
        !!ar_type.to_s.match(ActiveRecord::ConnectionAdapters::PostgreSQL::OID.to_s)
      end

      @grouped_types ||= (grouped_types[true] + grouped_types[false])
    end

    def value
      ActiveRecord::Type::Value.new
    end

    def new_array(subtype)
      ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(subtype)
    end
  end
end
