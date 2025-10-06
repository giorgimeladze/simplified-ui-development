module GeneralLinks
  def set_header_links
    user = current_user || User.new
    @header_links = []

    @header_links << { rel: 'collection', title: 'All Articles', method: 'GET', href: articles_path }

    @header_links << { rel: 'my-articles', title: 'My Articles', method: 'GET', href: articles_my_articles_path }

    @header_links << { rel: 'review-articles', title: 'Review Articles', method: 'GET', href: articles_articles_for_review_path }

    @header_links << { rel: 'deleted-articles', title: 'Deleted Articles', method: 'GET', href: articles_deleted_articles_path }

    if user_signed_in?
      @header_links << { rel: 'sign-out', title: 'Sign Out', method: 'DELETE', href: destroy_user_session_path}
    else
      @header_links << { rel: 'sign-in', title: 'Sign In', method: 'GET', href: new_user_session_path }
      @header_links << { rel: 'sign-up', title: 'Sign Up', method: 'GET', href: new_user_registration_path }
    end
  end
end