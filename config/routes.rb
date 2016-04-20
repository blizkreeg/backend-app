require 'sidekiq/web'
Rails.application.routes.draw do
  # monitor Sidekiq
  # TBD: move to standalone or protected on production
  mount Sidekiq::Web => '/sidekiq'

  # constraints subdomain :api do <-- TODO: UNCOMMENT BEFORE LAUNCH
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
        resources :accounts
      end
    end

    # TBD: COMMENT BEFORE GOING TO PROD!!

    # get '/admin/profile-review', to: 'admin#review_profiles'
    # post '/admin/update-review', to: 'admin#update_review'

    get '/admin', to: 'accounts#admin'
    post '/admin/create-matches', to: 'accounts#create_matches'
    post '/admin/check-mutual-matches', to: 'accounts#check_mutual_match'
    post '/admin/move-conversation', to: 'accounts#move_conversation'

    get 'login', to: 'accounts#login'
    get 'all', to: 'accounts#index'
    get 'show', to: 'accounts#show'
    get 'show/butler', to: 'accounts#show_butler_chat'
    get '/auth/:provider/callback', to: 'accounts#callback', as: :omniauth_callback
    delete '/accounts/destroy/:uuid', to: 'accounts#destroy'
    post 'reset_state', to: 'accounts#reset_state'
    post 'create-mutual-match', to: 'accounts#create_mutual_match'
    post 'reverse-gender', to: 'accounts#reverse_gender'
    post 'start-conversation', to: 'accounts#start_conversation'
    post 'update-conversation-state', to: 'accounts#update_conversation_state'
    post 'post-date-feedback', to: 'accounts#switch_to_post_date_feedback'
    post 'send-push-notification', to: 'accounts#send_push_notification'
  # end <-- TODO: UNCOMMENT BEFORE LAUNCH

  # post '/users', to: 'users#create'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
