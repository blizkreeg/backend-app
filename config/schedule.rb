# 15 minutes into every hour, check for new matches
#15 * * * * cd /home/deploy/backend-app/current && /home/deploy/.rbenv/shims/bundle exec rake matches:generate_new >> /home/deploy/backend-app/shared/log/cron.log 2>&1
# every 30 minutes, every hour, check for mutual matches
#*/30 * * * * cd /home/deploy/backend-app/current && /home/deploy/.rbenv/shims/bundle exec rake matches:find_mutual >> /home/deploy/backend-app/shared/log/cron.log 2>&1
# every 15 minutes, every hour, see if new matches should be delivered for some users
#*/15 * * * * cd /home/deploy/backend-app/current && /home/deploy/.rbenv/shims/bundle exec rake matches:ready_for_new >> /home/deploy/backend-app/shared/log/cron.log 2>&1
# once a day incomplete profiles
#0 13 * * * cd /home/deploy/backend-app/current && /home/deploy/.rbenv/shims/bundle exec rake engagement:day2_complete_profile >> /home/deploy/backend-app/shared/log/cron.log 2>&1
# 7th day engagement email
#0 8 * * 0 cd /home/deploy/backend-app/current && /home/deploy/.rbenv/shims/bundle exec rake engagement:day7_comeback >> /home/deploy/backend-app/shared/log/cron.log 2>&1

every :hour, roles: [:master] do
  rake "brew:reminder_to_confirm_24h_prior"
end

every 5.minutes, roles: [:master] do
  rake "brew:expire_past_ones"
end
