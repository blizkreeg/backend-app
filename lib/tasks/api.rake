namespace :api do
  desc "convert YAML API schema file to JSON"
  task :yaml_to_json => :environment do
    yml_filepath = File.join(Rails.root, 'db', 'api_schema.yml')
    json_filepath = File.join(Rails.root, 'db', 'api_schema.json')

    exec "cat #{yml_filepath} | ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML::load(ARGF.read))' > #{json_filepath}"
  end
end
