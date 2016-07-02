Rails.application.routes.draw do
  constraints SubdomainConstraint.new('app-api') do
    scope module: 'api' do
      namespace 'v1' do
        get '/home', to: 'profiles#home'

        post '/sign-in', to: 'profiles#sign_in'
        post '/waiting-list', to: 'profiles#add_to_waiting_list'

        post '/profiles/:uuid/sign-out', to: 'profiles#sign_out'
        post '/profiles/:uuid/activate', to: 'profiles#activate'
        post '/profiles/:uuid/deactivate', to: 'profiles#deactivate'
        patch '/profiles/:uuid/settings', to: 'profiles#update_settings'

        resources :profiles, param: :uuid do
          resources :photos, only:  [:create, :show, :destroy, :index, :update]
          get '/facebook-albums', to: 'photos#show_facebook_albums'
          get '/facebook-albums/:album_id', to: 'photos#show_facebook_album_photos'

          resources :matches, only: [:index, :show, :update, :destroy], except: [:create]
          resources :conversations, only: [:update, :show] do
            post '/health',           to: 'conversations#record_conversation_health'
            post '/ready-to-meet',    to: 'conversations#record_ready_to_meet'
            post '/date-details',     to: 'conversations#record_meeting_details'
            get '/date-suggestions',  to: 'conversations#show_date_suggestions'
          end
          resources :messages, only: [:create]
          resources :real_dates, only: [:show, :update], path: '/real-dates'

          # bulk update matches
          patch 'matches', to: 'matches#update', as: :matches_bulk
        end

        post '/profiles/report', to: 'profiles#report'
        get '/profiles/:uuid/state', to: 'profiles#get_state', as: :get_state

        post '/accounts/send-push-notification', to: 'accounts#send_push_notification'
        post '/accounts/update-user-new-butler-message', to: 'accounts#update_user_new_butler_message'
        resources :accounts
      end
    end
  end

  #
  # ADMIN DASHBOARD
  #
  constraints SubdomainConstraint.new('admin') do
    mount Sidekiq::Web, at: "/sq"

    get '/', to: redirect('/dashboard')
    get  '/dashboard', to: 'admin#dashboard'
    post '/lookup-user', to: 'admin#lookup_user'
    get  '/show-user/:uuid', to: 'admin#show_user', as: 'admin_show_user'
    get '/all-users', to: 'admin#all_users', as: 'admin_all_users'
    get  '/unmoderated', to: 'admin#unmoderated'
    get  '/suspicious', to: 'admin#suspicious'
    post '/moderate_user', to: 'admin#moderate_user', as: 'admin_moderate_user'
    get  '/review-photos', to: 'admin#review_photos'
    post '/moderate-photos', to: 'admin#moderate_photos', as: 'admin_moderate_photos'
    get '/new-butler-chats', to: 'admin#new_butler_chats'
    get '/show-butler-chat/:profile_uuid', to: 'admin#show_butler_chat', as: 'admin_show_butler_chat'
    post '/update-butler-chat-flag', to: 'admin#update_butler_chat_flag', as: 'admin_update_butler_chat_flag'
    post '/send-butler-chat-notification', to: 'admin#send_butler_chat_notification', as: 'admin_send_butler_chat_notification'
    post '/logout', to: 'admin#logout', as: 'admin_logout'
    get '/profiles-marked-for-deletion', to: 'admin#profiles_marked_for_deletion', as: 'admin_profiles_marked_for_deletion'
    post '/moderate-user-stb', to: 'admin#moderate_user_stb', as: 'admin_moderate_user_stb'
    post '/assign-desirability-score', to: 'admin#assign_desirability_score_user', as: 'admin_assign_desirability_score_user'
    get '/conversations', to: 'admin#show_conversations'
    get '/dates', to: 'admin#show_dates'

    # old admin dashboard - TBD: remove/merge this functionality into above
    get '/login', to: 'accounts#login'
    get '/all', to: 'accounts#index'
    get '/show', to: 'accounts#show'
    get '/show/butler', to: 'accounts#show_butler_chat'
    get '/auth/:provider/callback', to: 'accounts#callback', as: :omniauth_callback
    delete '/accounts/destroy/:uuid', to: 'accounts#destroy'
    post '/reset_state', to: 'accounts#reset_state'
    post '/create-mutual-match', to: 'accounts#create_mutual_match'
    post '/reverse-gender', to: 'accounts#reverse_gender'
    post '/start-conversation', to: 'accounts#start_conversation'
    post '/update-conversation-state', to: 'accounts#update_conversation_state'
    post '/post-date-feedback', to: 'accounts#switch_to_post_date_feedback'
    post '/send-push-notification', to: 'accounts#send_push_notification'

    # stb dashboard
    get '/stb-dashboard', to: 'admin#stb_dashboard'
  end

  constraints SubdomainConstraint.new('events') do
    # events
    get '/rsvp-stb', to: 'events#rsvp_stb'
    post '/register-stb', to: 'events#register_stb'
    delete '/cancel-stb', to: 'events#cancel_stb'
    get '/registered', to: 'events#registered'
    get '/payment-success', to: 'events#payment_success'
  end

  get '*unmatched_route', to: 'application#route_not_found'
end
