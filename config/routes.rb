ProformaDA::Application.routes.draw do

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
      match 'revisions(/:number)' => 'disbursements#revisions', via: [:get, :post]
    end
    collection do
      match 'search' => "disbursements#search", via: [:get, :post]
    end
  end
  match 'proforma_disbursements/:id(/:revision_number)' => 'disbursements#published', :as => :published, via: [:get, :post]
  match 'pfda/:id(/:revision_number)' => 'disbursements#published', :as => :published_short, via: [:get, :post]
  match 'pda/:id(/:revision_number)' => 'disbursements#published', :as => :published_short_2, via: [:get, :post]

  get 'api/ping' => "api#ping"
  match 'api/nominations' => "api#nominations", via: [:get, :post]
  match 'api/nomination_details' => "api#nomination_details", via: [:get, :post]
  match 'api/agency_fees' => "api#agency_fees", via: [:get, :post]

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
  resources :vessels do
    collection do
      get 'search/:name', to: "vessels#search"
    end
  end
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
  resources :named_services do
    collection do
      post 'sort', to: "services#sort"
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

  # auth
  post 'auth/register' => 'auth#register'
  post 'auth/check' => 'auth#check'
  get 'auth/login' => 'auth#login'
  get 'auth/logout' => 'auth#logout'

  get "home/index"
  get "landing/index"

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'home#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
