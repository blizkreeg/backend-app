# TODO break up this file into multiple files
Rails.application.routes.draw do

  # Brew

  resources :brews, param: :slug, only: [:index, :new, :create, :edit, :update, :show] do
    post '/show-interest', to: 'brews#show_interest', as: :show_interest
    get '/register', to: 'brews#register', as: :register
    get '/registered', to: 'brews#registered', as: :registered
    get '/conversation', to: 'brews#conversation', as: :conversation
  end

  # onboarding
  get '/join-waitlist', to: 'brews#add_to_waitlist'
  get '/show-waitlist', to: 'brews#show_on_waitlist'
  post '/update-phone', to: 'brews#update_phone', as: :update_phone

  # profile
  get '/show-profile/:show_profile_uuid', to: 'brews#show_profile', as: :show_profile

  # intros
  get '/introductions', to: 'brews#introductions', as: :introductions
  post '/request-introduction', to: 'brews#request_introduction', as: :request_introduction
  post '/accept-introduction', to: 'brews#accept_introduction', as: :accept_introduction

  # social
  get '/social', to: 'brews#social', as: :social
  get '/new-social', to: 'brews#new_social', as: :new_social
  get '/edit-social/:social_update_id', to: 'brews#edit_social', as: :edit_social
  post '/destroy-social', to: 'brews#destroy_social', as: :destroy_social
  patch '/update-social', to: 'brews#update_social', as: :update_social
  post '/publish-social', to: 'brews#publish_social', as: :publish_social
  post '/toggle-social-like', to: 'brews#toggle_social_like', as: :toggle_social_like
  get '/social/:social_update_id/talk', to: 'brews#social_comment_stream', as: :social_comment_stream
  post '/social/:social_update_id/talk', to: 'brews#post_social_comment', as: :post_social_comment
  get '/social-rules', to: 'brews#rules_of_social_engagement', as: :social_rules

  get '/conversations', to: 'brews#conversations', as: :conversations
  get '/community', to: 'brews#community', as: :community
  get '/conversation-with/:profile_uuid', to: 'brews#conversation_with', as: :conversation_with

  # membership
  get '/membership-status', to: 'brews#membership_status', as: :membership_status
  post '/paid-membership-instamojo', to: 'brews#process_instamojo_payment', as: :process_instamojo_payment

  root to: 'pages#homepage'

  get '/hp', to: 'pages#hp'
  get '/insider-membership', to: 'pages#membership'
  get '/partnerships', to: 'pages#partnerships'
  get '/who-why-join-ekcoffee', to: 'pages#whyjoin'
  get '/faqs', to: 'pages#faqs'
  get '/privacy', to: 'pages#privacy'

  # ekCoffee app API

  constraints SubdomainConstraint.new('app-api') do
    scope module: 'api' do
      namespace 'v1' do
        get '/home', to: 'profiles#home'

        resources :posts, only: [:index]

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

  constraints SubdomainConstraint.new('events') do
    # events
    get '/rsvp-stb', to: 'events#rsvp_stb'
    post '/register-stb', to: 'events#register_stb'
    delete '/cancel-stb', to: 'events#cancel_stb'
    get '/registered', to: 'events#registered'
    get '/payment-success', to: 'events#payment_success'
    get '/announce-interests', to: 'events#announce_interests'
    post '/register-interests', to: 'events#register_interests', as: :register_interests
  end

  # Admin Dashboard

  constraints SubdomainConstraint.new('admin') do
    mount Sidekiq::Web, at: "/sq"

    get  '/dashboard', to: 'admin#dashboard'
    post '/lookup-user', to: 'admin#lookup_user'
    get  '/show-user/:uuid', to: 'admin#show_user', as: 'admin_show_user'
    get '/all-users', to: 'admin#all_users', as: 'admin_all_users'
    get  '/unmoderated', to: 'admin#unmoderated'
    get  '/others', to: 'admin#others'
    get  '/suspicious', to: 'admin#suspicious'
    post '/moderate_user', to: 'admin#moderate_user', as: 'admin_moderate_user'
    get  '/review-photos', to: 'admin#review_photos'
    post '/moderate-photos', to: 'admin#moderate_photos', as: 'admin_moderate_photos'
    get '/new-butler-chats', to: 'admin#new_butler_chats'
    get '/show-butler-chat/:profile_uuid', to: 'admin#show_butler_chat', as: 'admin_show_butler_chat'
    post '/update-butler-chat-flag', to: 'admin#update_butler_chat_flag', as: 'admin_update_butler_chat_flag'
    post '/send-butler-chat-notification', to: 'admin#send_butler_chat_notification', as: 'admin_send_butler_chat_notification'
    get '/logout', to: 'admin#logout', as: 'admin_logout'
    get '/profiles-marked-for-deletion', to: 'admin#profiles_marked_for_deletion', as: 'admin_profiles_marked_for_deletion'
    post '/delete-profiles-marked-for-deletion', to: 'admin#delete_profiles_marked_for_deletion', as: 'admin_delete_profiles_marked_for_deletion'
    post '/assign-desirability-score', to: 'admin#assign_desirability_score_user', as: 'admin_assign_desirability_score_user'
    get '/conversations', to: 'admin#show_conversations'
    get '/dates', to: 'admin#show_dates'
    post '/delete-user', to: 'admin#destroy_user', as: 'admin_destroy_user'
    post '/approve-brew', to: 'admin#approve_brew', as: 'admin_approve_brew'
    post '/reject-brew', to: 'admin#reject_brew', as: 'admin_reject_brew'
    get '/search', to: 'admin#search', as: 'admin_search_users'
    get '/content', to: 'admin#content', as: 'admin_content'
    post '/create-content', to: 'admin#create_content', as: 'admin_create_content'
    get '/tribe-questions', to: 'admin#social_questions', as: 'admin_social_questions'
    post '/activate-social-question', to: 'admin#activate_social_question', as: 'admin_activate_social_question'
    post '/create-social-question', to: 'admin#create_social_question', as: 'admin_create_social_question'

    # old admin dashboard - TBD: remove/merge this functionality into above
    get '/login', to: 'accounts#login'
    get '/all', to: 'accounts#index'
    get '/show', to: 'accounts#show'
    get '/test-flow', to: 'accounts#test_flow'
    post '/update-test-flow', to: 'accounts#update_test_flow'
    post '/create-matches', to: 'accounts#create_matches'
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
    get '/brew-dashboard', to: 'admin#brew_dashboard', as: :brew_dashboard

    # crud brews
    get '/manage/brews/new', to: 'admin#new_brew', as: :admin_new_brew
    get '/manage/brews/edit/:brew_id', to: 'admin#edit_brew', as: :admin_edit_brew
    post '/manage/brews/create', to: 'admin#create_brew', as: :admin_create_brew
    patch '/manage/brews/update', to: 'admin#update_brew', as: :admin_update_brew
  end

  # TODO remove this
  get '/moosecsv', to: 'moose#moosecsv'

  get '*unmatched_route', to: 'application#route_not_found'
end
