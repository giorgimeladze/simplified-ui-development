# frozen_string_literal: true

class ArticlesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_article,
                only: %i[show submit reject reject_feedback approve_private resubmit archive publish make_visible
                         make_invisible]

  def index
    articles = Article.visible

    rendering_articles(articles, 'All Articles')
  end

  def my_articles
    articles = current_user.articles

    rendering_articles(articles, 'My Articles')
  end

  def articles_for_review
    authorize Article, :articles_for_review?

    articles = Article.where(status: 'review')

    rendering_articles(articles, 'Articles for Review')
  end

  def deleted_articles
    authorize Article, :deleted_articles?

    articles = current_user.admin? ? Article.where(status: 'archived') : current_user.articles.where(status: 'archived')

    rendering_articles(articles, 'Archived Articles')
  end

  # GET /articles/:id
  def show
    rendered_article = ArticleBlueprint.render_as_hash(@article, view: :show, context: { current_user: current_user })
    article_comments = CommentBlueprint.render_as_hash(@article.visible_comments(current_user), view: :index,
                                                                                                context: { current_user: current_user })

    # HAL-style _embedded format
    rendered_article[:_embedded] = {
      comments: article_comments
    }

    @html_content = render_to_string(partial: 'article', locals: { article: rendered_article }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Article')

    respond_to do |format|
      format.html { render :show }
      format.json { render json: { article: rendered_article, links: @links } }
    end
  end

  # GET /articles/new
  def new
    @article = Article.new
    authorize @article
    @html_content = render_to_string(partial: 'form', locals: { article: @article }, formats: [:html])
    @links = @article.hypermedia_new_links(current_user)
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { article: @article, links: @links } }
    end
  end

  # POST /articles
  def create
    @article = Article.new(article_params)
    @article.user = current_user
    authorize @article

    if @article.save
      respond_to do |format|
        format.html { redirect_to article_path(@article), notice: 'Article was successfully created.' }
        format.json do
          render json: { article: @article.slice(:id, :title, :content, :status, :user_id) }, status: :created
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # FSM Event Actions
  def submit
    transition_article(:submit)
  end

  def reject_feedback
    authorize @article, :reject?
    @html_content = render_to_string(partial: 'reject_feedback_form', formats: [:html])
    @links = @article.hypermedia_edit_links(current_user)
    respond_to do |format|
      format.html { render :reject_feedback }
      format.json { render json: { article: @article.slice(:id, :title, :content, :status, :user_id), links: @links } }
    end
  end

  def reject
    if params[:rejection_feedback].present?
      @article.update(rejection_feedback: params[:rejection_feedback])
      transition_article(:reject)
    else
      respond_to do |format|
        format.html { redirect_to reject_feedback_article_path(@article), alert: 'Rejection feedback is required.' }
        format.json { render json: { errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
  end

  def approve_private
    transition_article(:approve_private)
  end

  def resubmit
    transition_article(:resubmit)
  end

  def archive
    transition_article(:archive)
  end

  def publish
    transition_article(:publish)
  end

  def make_visible
    transition_article(:make_visible)
  end

  def make_invisible
    transition_article(:make_invisible)
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :content)
  end

  def rendering_articles(articles, title)
    rendered_articles = ArticleBlueprint.render_as_hash(articles, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'list', locals: { articles: rendered_articles, title: title },
                                     formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_index(current_user, 'Article')

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { articles: rendered_articles, links: @links } }
    end
  end

  def transition_article(event)
    # Event-level authorization
    policy = ArticlePolicy.new(current_user, @article)
    raise Pundit::NotAuthorizedError unless policy.respond_to?("#{event}?") && policy.public_send("#{event}?")

    if @article.aasm.may_fire_event?(event)
      @article.aasm.fire!(event)
      respond_to do |format|
        format.html { redirect_to article_path(@article), notice: 'Transition applied.' }
        format.json do
          rendered_article = ArticleBlueprint.render_as_hash(@article, view: :show,
                                                                       context: { current_user: current_user })
          render json: { article: rendered_article }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article_path(@article), alert: 'Transition not allowed.' }
        format.json { render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
