FocusPull::Application.routes.draw do
  #get "login/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  match 'login' => 'login#form'
  match 'login/retrieve_archive' => 'login#release_archive'
  
  match 'login/prepare_for_retrieve' => 'login#prepare_for_retrieve'
  match 'login/download_archive' => 'login#download_archive'
  match 'login/parse_archive' => 'login#parse_archive'
  
  
  match 'focus/Portfolio.mm' => 'maps#send_simple_map'
  match 'focus/Recent-changes.mm' => 'maps#send_delta_map'
  match 'focus/Recently-completed.mm' => 'maps#send_done_map'
  match 'focus/Recently-added-projects.mm' => 'maps#send_new_project_map'
  match 'focus/Metamap.mm' => 'maps#send_meta_map'
  match 'focus/wordcloud.pdf' => 'clouds#create'

  match 'focus/save-settings' => 'maps#save_settings'

  match 'focus' => 'maps#list'

  match 'time_spent' => 'history#time_spent'
  
  match 'view_tree_map' => 'tree_map#view'
  
  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

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

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

root :to => "login#form"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
