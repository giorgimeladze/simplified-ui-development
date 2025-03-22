module GeneralLinks
  def set_header_links
    user = current_user || User.new
    @header_links = []

    @header_links << { name: 'All Articles', action: 'GET', href: articles_path } # everyone can see published

    if user.editor? || user.admin?
      @header_links << { name: 'My Articles', action: 'GET', href: articles_my_articles_path }
    end

    if user.admin?
      @header_links << { name: 'Review Articles', action: 'GET', href: articles_articles_for_review_path }
    end

    if user.admin? || user.editor?
      @header_links << { name: 'Deleted Articles', action: 'GET', href: articles_deleted_articles_path }
    end

    if user_signed_in?
      @header_links << { name: 'Sign Out', action: 'DELETE', href: destroy_user_session_path}
    else
      @header_links << { name: 'Sign In', action: 'GET', href: new_user_session_path }
      @header_links << { name: 'Sign Up', action: 'GET', href: new_user_registration_path }
    end
  end
end