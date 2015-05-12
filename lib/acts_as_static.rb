module ActsAsStatic

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Configuration options are:
    #
    # * +root+ - specifies the root directory for static pages
    # * +template+ - specifies the template for static pages
    # 
    # Example: <tt>acts_as_static :root => File.join(RAILS_ROOT, "app", "views", "static") }</tt>
    def acts_as_static(options = {})
      configuration = { :root => File.join(RAILS_ROOT, "app", "views", "static") }
      configuration.update(options) if options.is_a?(Hash)

      class_eval <<-EOV 
        include ActsAsStatic::InstanceMethods

        verify :params => :url, :only => :show, :redirect_to => "/"
        before_filter :ensure_valid, :only => :show
        
        def acts_as_static_root
          '#{configuration[:root]}'
        end

        private :acts_as_static_root
      EOV
    end
  end

  module InstanceMethods
    def show
      render :template => current_template, :layout => current_layout
    end
    
    private

    def current_page
      path = params[:url].join("/")
      if File.directory?(File.join(acts_as_static_root, path))
        "#{path}/index.html.erb"
      else
        "#{path}.html.erb"
      end
    end

    def current_layout
      "application"
    end

    def current_template
      File.join(acts_as_static_root, current_page)
    end

    def ensure_valid
      unless File.exists?(File.join(acts_as_static_root, current_page))
        render :file => File.join(RAILS_ROOT, "public", "404.html"), :status => 404
        return false
      end
    end
  end

end

ActionController::Base.class_eval do
  include ActsAsStatic
end
