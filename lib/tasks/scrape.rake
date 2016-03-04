namespace :scrape do
  task :cafes => :environment do
    Scrape.run('mumbai', 'cafes')
  end
end
