class JsonbUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attr, value)
    return if value.blank?

    has_record = record.class.send("with_#{attr}", value).take
    record.errors[attr] << Errors::EMAIL_EXISTS_ERROR_STR if has_record.present? && has_record.uuid != record.uuid
  end
end
