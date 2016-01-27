module JsonSchemaValidator
  extend ActiveSupport::Concern

  protected

  def validate_json_schema
    path_components = request.path.split('/') # => should yield ['', 'v{x}', 'path', 'to', 'endpoint']
    api_version_str = path_components.second # v{x}
    endpoint_str = ['/', path_components.last(path_components.size-2).join('/')].join
    http_method = request.method.downcase

    schema_definition = JSON.parse(File.read(File.join(Rails.root, 'db', 'api_schema.json')))
    substitute_parameters = request.path_parameters.select { |k,v| endpoint_str.include? v }
    substitute_parameters.map { |k,v| endpoint_str.gsub!(v, ":#{k}") }
    object_schema = schema_definition["paths"][endpoint_str][http_method] rescue nil

    if object_schema.blank?
      Rails.logger.error "Unable to look up schema definition for path #{request.path}"
      return
    end

    (object_schema["parameters"] || []).each do |parameter|
      next if parameter["in"] != "body"
      JSON::Validator.validate!(parameter["schema"], params)
    end
  end
end
