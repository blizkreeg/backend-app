module JsonSchemaValidator
  extend ActiveSupport::Concern

  protected

  def validate_json_schema
    path_components = request.path.split('/')
    api_version_str = path_components.second
    endpoint_str = "/#{path_components.third}"
    http_method = request.method.downcase

    schema_definition = JSON.parse(File.read(File.join(Rails.root, 'db', 'api_schema.json')))
    schema_object = schema_definition["paths"][endpoint_str][http_method]["parameters"].first["schema"]

    JSON::Validator.validate!(schema_object, params)
  end
end
