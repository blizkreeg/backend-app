class PagesController < WebController
  layout 'homepage'

  def homepage
    if @current_profile.present?
      redirect_to controller: :brews, action: :index
      return
    end

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
end
