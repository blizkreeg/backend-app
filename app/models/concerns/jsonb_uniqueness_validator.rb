class JsonbUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    has_record = record.class.send("with_#{attr}", value).take
    record.errors[attr] << "already exists" if has_record.present? && has_record.uuid != record.uuid
  end
end
