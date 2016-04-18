namespace :scrape do
  task :cafes, [:city] => :environment do |t, args|
    Scrape.run(args[:city], 'cafes')
  end
end
