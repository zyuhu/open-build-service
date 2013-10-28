require 'opensuse/backend'

class Configuration < ActiveRecord::Base

  include CanRenderModel

  OPTIONS_YML =  { :title => nil,
                   :description => nil,
                   :name => nil,                     # from BSConfig.pm
                   :download_on_demand => nil,       # from BSConfig.pm
                   :enforce_project_keys => nil,     # from BSConfig.pm
                   :anonymous => CONFIG['allow_anonymous'],
                   :registration => CONFIG['new_user_registration'],
                   :default_access_disabled => CONFIG['default_access_disabled'],
                   :allow_user_to_create_home_project => CONFIG['allow_user_to_create_home_project'],
                   :disallow_group_creation => CONFIG['disallow_group_creation_with_api'],
                   :change_password => CONFIG['change_passwd'],
                   :hide_private_options => CONFIG['hide_private_options'],
                   :gravatar => CONFIG['use_gravatar'],
                   :download_url => CONFIG['download_url'],
                   :ymp_url => CONFIG['ymp_url'],
                   :errbit_url => CONFIG['errbit_host'],
                   :bugzilla_url => CONFIG['bugzilla_host'],
                   :http_proxy => CONFIG['http_proxy'],
                   :no_proxy => nil,
                   :theme => CONFIG['theme'],
                 }
  ON_OFF_OPTIONS = [ :anonymous, :default_access_disabled, :allow_user_to_create_home_project, :disallow_group_creation, :change_password, :hide_private_options, :gravatar, :download_on_demand, :enforce_project_keys ]
   
  class << self
    def map_value(key, value)
      if ON_OFF_OPTIONS.include? key
        # make them boolean
        if [ :on, ":on", "on", "true", true ].include? value
           value = true
        else
           value = false
        end
      end
      return value
    end

    def anonymous?
      @@anonymous ||= Configuration.limit(1).pluck(:anonymous).first
    end
   
    def registration
      Configuration.limit(1).pluck(:registration).first
    end

    def download_url
      @@download_url ||= Configuration.limit(1).pluck(:download_url).first
    end

    def ymp_url
      @@ymp_url ||= Configuration.limit(1).pluck(:ymp_url).first
    end

    def use_gravatar?
      @@use_gravatar ||= Configuration.limit(1).pluck(:gravatar).first
    end

    # Check if ldap group support is enabled?
    def ldapgroup_enabled?
      return CONFIG['ldap_mode'] == :on && CONFIG['ldap_group_support'] == :on
    end

    def errbit_url
      begin
        Configuration.limit(1).pluck(:errbit_url).first
      rescue ActiveRecord::ActiveRecordError
        # there is a boostrap issue here - you need to run db:setup to get the
        # table, but the initializer checks the configuration
      end
    end

    def save!
      super
      self.write_to_backend
    end

    def write_to_backend
      Configuration.first.delay.write_to_backend
    end
  end

  def update_from_options_yml()
    # strip the not set ones
    attribs = ::Configuration::OPTIONS_YML.clone
    attribs.keys.each do |k|
      if attribs[k].nil?
        attribs.delete(k)
        next
      end

      attribs[k] = ::Configuration::map_value(k, attribs[k])
    end

    self.update_attributes(attribs)
    self.save!
    self.write_to_backend
  end

  def write_to_backend
    path = "/configuration"
    logger.debug "Write configuration information to backend..."
    Suse::Backend.put_source(path, self.render_xml)
  end

end
