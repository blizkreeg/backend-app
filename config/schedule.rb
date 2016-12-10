every :hour, roles: [:master] do
  rake "brew:reminder_to_confirm_24h_prior"
end

every 5.minutes, roles: [:master] do
  rake "brew:expire_past_ones"
end
