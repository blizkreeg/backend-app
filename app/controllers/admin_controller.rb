class AdminController < ApplicationController
  layout 'application'

  def review_profiles
    @profiles = Profile.with_pending_human_review(true).includes(:review)
  end

  def update_review
    review = ProfileReview.find params[:review_id]
    review.update! params[:review]
  end
end
