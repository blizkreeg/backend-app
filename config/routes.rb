Rails.application.routes.draw do

  # constraints subdomain :api do <-- TODO: UNCOMMENT BEFORE LAUNCH
    scope module: 'api' do
      namespace 'v1' do
        post '/sign-in', to: 'profiles#sign_in'
        post '/waiting-list', to: 'profiles#add_to_waiting_list'

        resources :profiles, param: :uuid do
          resources :photos, only:  [:create, :show, :destroy, :index]
          resources :matches, only: [:index, :show, :update], except: [:create, :destroy]

          # bulk update matches
          patch 'matches', to: 'matches#update', as: :matches_bulk
        end

        get 'profiles/:uuid/state', to: 'profiles#get_state', as: :get_state

        resources :accounts
      end
    end

    get '/auth/:provider/callback', to: 'accounts#sign_in', as: :omniauth_callback
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
