Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  ## music database
  get 'api/database' => 'database#index'
  ## active playlist
  get 'api/queue' => 'queue#index'

  put 'api/queue/play' => 'queue#play'
  put 'api/queue/stop' => 'queue#stop'
  put 'api/queue/pause' => 'queue#pause'
  put 'api/queue/unpause' => 'queue#unpause'
  put 'api/queue/next' => 'queue#go_next'
  put 'api/queue/previous' => 'queue#go_previous'

  put 'api/queue/add_file' => 'queue#add_file'
  put 'api/queue/add_path' => 'queue#add_path'
  put 'api/queue/move' => 'queue#move'
  put 'api/queue/remove' => 'queue#remove'

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
