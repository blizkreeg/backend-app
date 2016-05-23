namespace :places do
  task :seed_cafes, [:city] => :environment do |t, args|
    Places.seed(args[:city], 'cafes')
  end
end
