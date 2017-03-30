namespace :admin do
  desc "Remove users marked for deletion"
  task :delete_users => :environment do
    users_marked_for_deletion = Profile.is_marked_for_deletion
    count = users_marked_for_deletion.count
    users_marked_for_deletion.each do |profile|
      puts "schedule #{profile.uuid} for deletion"
      Profile.delay.destroy(profile.uuid)
    end
    puts "scheduled #{count} users for deletion"
  end
end
