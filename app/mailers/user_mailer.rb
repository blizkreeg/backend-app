class UserMailer < ApplicationMailer
  def remind_matches(profile_uuid, match_profiles_uuids)
    @profile = Profile.find(profile_uuid) rescue nil
    return if @profile.blank?
    @match_profiles = match_profiles_uuids.map { |uuid| Profile.find(uuid) rescue nil }.compact
    return if @match_profiles.blank?
    mail(to: @profile.email, subject: "All the people who have liked you on ekCoffee")
  end
end
