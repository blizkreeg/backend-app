class WebController < ApplicationController
  protect_from_forgery with: :exception

  before_action :set_domain
  before_action :check_for_mobile_device
  before_action :check_if_request_from_app
  before_action :load_ekcoffee_profile, if: lambda { from_app? }

  after_action :set_response_headers

  # headers passed on the web view request
  EKCOFFEE_APP_HEADER = 'X-EKCOFFEE-APP'
  EKCOFFEE_APP_PROFILE_UUID_HEADER = 'X-EKCOFFEE-PROFILE-UUID'

  helper_method :anonymous?, :current_profile_is_admin?, :is_joinbrew?, :is_ekcbrew?

  rescue_from ActionView::MissingTemplate, with: :render_404

  protected

  def is_joinbrew?
    @domain == 'joinbrew.com'
  end

  def is_ekcbrew?
    @domain == 'brew.ekcoffee.com'
  end

  def mobile_device?
    @mobile_device
  end

  def logged_in?
    @current_profile.present?
  end

  def anonymous?
    @current_profile.blank?
  end

  def current_profile_is_admin?
    @current_profile.present? && @current_profile.staff_or_internal
  end

  private

  def set_domain
    @domain = request.host
  end

  # http://detectmobilebrowsers.com/
  def check_for_mobile_device
    if request.user_agent.blank?
      @mobile_device = false
    else
      @mobile_device = /(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.match(request.user_agent) || /1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.match(request.user_agent[0..3])
    end
  end

  # all ekc app requests must have this param set
  def check_if_request_from_app
    @request_from_ekc_app = true if from_app?

    # all app requests are treated mobile, obviously.
    if @request_from_ekc_app
      @mobile_device = true
      session[:request_from_ekc_app] = true
    end
  end

  def load_ekcoffee_profile
    uuid = request_uuid || session[:uuid]

    raise "You're not logged in" if uuid.blank?

    @current_profile = Profile.find(uuid)
    session[:uuid] = @current_profile.uuid
  rescue ActiveRecord::RecordNotFound => err
    raise err
  rescue => err
  end

  def from_app?
    request.headers[EKCOFFEE_APP_HEADER] == '1' ||
    session[:request_from_ekc_app] ||
    params[:ekcapp] == '1' # #NotProudOfThis #HackSoWeCanTestInBrowser #AlsoNeededForEarlierAppVersions
  end

  def request_uuid
    request.headers[EKCOFFEE_APP_PROFILE_UUID_HEADER] ||
    params[:uuid] # #NotProudOfThis #HackSoWeCanTestInBrowser #AlsoNeededForEarlierAppVersions
  end

  def set_response_headers
    case Rails.env
    when 'development'
        response.headers['X-Frame-Options'] = "ALLOW-FROM http://localhost:3000/"
    when 'test'
      response.headers['X-Frame-Options'] = "ALLOW-FROM https://test-app.ekcoffee.com/"
    when 'production'
      response.headers['X-Frame-Options'] = "ALLOW-FROM https://admin.ekcoffee.com/"
    end
  end

  def render_404
    render file: "#{Rails.root}/public/404.html", status: 404, layout: false
  end
end
