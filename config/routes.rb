ProformaDA::Application.routes.draw do
  #devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks"}
  devise_for :users, path: '', path_names: {sign_in: 'users/auth/saml', sign_out: 'sign_out'}

  #devise_scope :user do
    #get '/users/auth/saml', :to => 'devise/sessions#new', :as => :new_user_session
    #get '/sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  #end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products


  resources :disbursements do
    member do
      match 'status/:status' => 'disbursements#status', via: [:get, :post]
      get 'print'
      get 'access_log'
    end
    collection do
      match 'search' => "disbursements#search", via: [:get, :post]
    end
  end
  match 'proforma_disbursements/:id' => 'disbursements#published', :as => :published, via: [:get, :post]
  match 'pfda/:id' => 'disbursements#published', :as => :published_short, via: [:get, :post]

  resources :ports do
    resources :terminals do
      resources :services do
        collection do
          post 'sort'
        end
      end
      resources :tariffs
    end
    resources :services do
      collection do
        post 'sort'
      end
    end
    resources :tariffs
  end
  resources :vessels
  resources :companies do
    collection do
      get 'search/:name', to: "companies#search"
    end
  end
  resources :taxes
  resources :cargo_types do
    collection do
      post 'enabled'
    end
  end

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  post 'jsonrpc' => 'jsonrpc#index'

  get "home/index"
  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
