class JsonbUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    record.errors[attr] << "already exists" if record.class.send("with_#{attr}", value).present?
  end
end
