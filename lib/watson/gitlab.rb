module Watson
  class Remote
    # GitLab remote access class
    # Contains all necessary methods to obtain access to, get issue list,
    # and post issues to GitLab
    class GitLab
    
    # Debug printing for this class
    DEBUG = false   

    class << self

    # [todo] - Allow closing of issues from watson? Don't like that idea but maybe
    # [review] - Properly scope Printer class so we dont need the Printer. for 
    #      method calls?
    # [todo] - Keep asking for user data until valid instead of leaving app


    # Include for debug_print
    include Watson
    
    ############################################################################# 
    # Setup remote access to GitLab
    # Get Username, Repo, and PW and perform necessary HTTP calls to check validity
    def setup(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      Printer.print_status "+", GREEN
      print BOLD + "Obtaining secret token from gitlab...\n" + RESET

      config.gitlab_api = ""
      config.gitlab_host = ""
      config.gitlab_project = ""
      
      debug_print "Updating config with new GitLab info\n"
      config.update_conf("gitlab_api", "gitlab_host", "gitlab_project")
    end

    def get_issues(config)

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"

      # Only attempt to get issues if API is specified 
      if config.gitlab_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end


      # Get all open tickets
      # Create options hash to pass to Remote::http_call 
      # Issues URL for GitLab
      opts = {:url        => "http://#{ config.gitlab_host }/api/v3/projects/#{ config.gitlab_project }/issues?private_token=#{ config.gitlab_api }",
          :ssl        => false,
          :method     => "GET",
          :verbose    => false 
           }

      _json, _resp  = Watson::Remote.http_call(opts)

      if _resp.code != "200"
        Printer.print_status "x", RED
        print BOLD + "Unable to access remote #{ config.gitlab_host }, GitLab API may be invalid\n" + RESET
        print "      Consider running --remote (-r) option to regenerate key\n\n"
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"

        debug_print "GitLab invalid, setting config var\n"
        config.gitlab_valid = false
        return false
      end

      # TODO: filter closed & labeled issue
      config.gitlab_issues[:closed] = _json.empty? ? Hash.new : _json
      config.gitlab_valid = true
      return true
    end 

    def post_issue(issue, config)
    # [todo] - Better way to identify/compare remote->local issues than md5
    #        Current md5 based on some things that easily can change, need better ident

      # Identify method entry
      debug_print "#{ self.class } : #{ __method__ }\n"
  
        
      # Only attempt to get issues if API is specified 
      if config.gitlab_api.empty?
        debug_print "No API found, this shouldn't be called...\n"
        return false
      end

      # Check that issue hasn't been posted already by comparing md5s
      # Go through all open issues, if there is a match in md5, return out of method
      # [todo] - Play with idea of making body of GitLab issue hash format to be exec'd
      #      Store pieces in text as :md5 => "whatever" so when we get issues we can
      #      call exec and turn it into a real hash for parsing in watson
      #      Makes watson code cleaner but not as readable comment on GitLab...?
      debug_print "Checking open issues to see if already posted\n"
      config.gitlab_issues[:open].each do | _open | 
        if _open["body"].include?(issue[:md5])
          debug_print "Found in #{ _open["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{ _open["title"] }\n"
      end 
      
      
      debug_print "Checking closed issues to see if already posted\n"
      config.gitlab_issues[:closed].each do  | _closed | 
        if _closed["body"].include?(issue[:md5])
          debug_print "Found in #{ _closed["title"] }, not posting\n"
          return false
        end
        debug_print "Did not find in #{ _closed["title"] }\n"
      end
    
      # We didn't find the md5 for this issue in the open or closed issues, so safe to post
    
      # Create the body text for the issue here, too long to fit nicely into opts hash
      # [review] - Only give relative path for privacy when posted
      _body = "__filename__ : #{ issue[:path] }\n" +
          "__line #__ : #{ issue[:line_number] }\n" + 
          "__tag__ : #{ issue[:tag] }\n" +
          "__md5__ : #{ issue[:md5] }\n\n" +
          "#{ issue[:context].join }\n"
      
      # Create option hash to pass to Remote::http_call
      # Issues URL for GitLab
      opts = {:url        => "http://#{ config.gitlab_host }/api/v3/projects/#{ config.gitlab_project }/issues?private_token=#{ config.gitlab_api }",
          :ssl        => false,
          :method     => "POST",
          :auth   => config.gitlab_api, 
          :data   => { "title" => issue[:title] + " [#{ issue[:path] }]",
                   "labels" => [issue[:tag], "watson"],
                   "body" => _body },
          :verbose    => false 
           }

      _json, _resp  = Watson::Remote.http_call(opts)
    
        
      # Check response to validate repo access
      # Shouldn't be necessary if we passed the last check but just to be safe
      if _resp.code != "201"
        Printer.print_status "x", RED
        print BOLD + "Post unsuccessful. \n" + RESET
        print "      Since the open issues were obtained earlier, something is probably wrong and you should let someone know...\n" 
        print "      Status: #{ _resp.code } - #{ _resp.message }\n"
        return false
      end
    
      return true 
    end

    end
    end
  end
end

