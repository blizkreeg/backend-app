class PagesController < WebController
  layout 'homepage'

  def homepage
    if @current_profile.present?
      if @current_profile.mobile_goto_uri.present?
        redirect_to @current_profile.mobile_goto_uri
      else
        redirect_to controller: :brews, action: :introductions
      end
      return
    end

    render 'pages/homepage', layout: 'homepage'
  end

  def hp
    render 'pages/homepage', layout: 'homepage'
  end

  def whyjoin
  end

  def faqs
  end

  def membership
  end

  def partnerships
  end

  def privacy
  end
end
