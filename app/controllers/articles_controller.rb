class ArticlesController < ApplicationController
  include LinksRenderer

  def index
    articles = Article.all

    rendered_articles = ArticleBlueprint.render_as_hash(articles, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'list', locals: { articles: rendered_articles })
    @links = ArticleLinks.general_index(current_user)

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { articles: rendered_articles, links: @links } }
    end
  end
end