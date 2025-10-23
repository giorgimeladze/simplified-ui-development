class Article2sController < ApplicationController  
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_article2, only: [:show, :submit, :reject, :reject_feedback, :approve_private, :resubmit, :archive, :publish, :make_visible, :make_invisible]

  def index
    article2s = Article2.visible
  
    rendering_article2s(article2s, 'All Articles')
  end
  
  def my_article2s
    article2s = current_user.article2s
  
    rendering_article2s(article2s, 'My Articles')
  end
  
  def article2s_for_review
    authorize Article2, :article2s_for_review?
  
    article2s = Article2.where(status: 'review')
  
    rendering_article2s(article2s, 'Articles for Review')
  end
  
  def deleted_article2s
    authorize Article2, :deleted_article2s?
  
    article2s = current_user.admin? ? Article2.where(status: 'archived') : current_user.article2s.where(status: 'archived')
  
    rendering_article2s(article2s, 'Archived Articles')
  end

   # GET /article2s/:id
   def show
    rendered_article2 = ArticleBlueprint.render_as_hash(@article2, view: :show, context: { current_user: current_user })
    article2_comments = Comment2Blueprint.render_as_hash(@article2.visible_comments(current_user), view: :index, context: { current_user: current_user })
    
    # HAL-style _embedded format
    rendered_article2[:_embedded] = {
      comments: article2_comments
    }
    
    @html_content = render_to_string(partial: 'articles/article', locals: { article: rendered_article2 }, formats: [:html])

    respond_to do |format|
      format.html { render 'articles/show' }
      format.json { render json: { article: @html_content } }
    end
  end

  # GET /article2s/new
  def new
    @article2 = Article2.new
    authorize @article2
    @html_content = render_to_string(partial: 'form', locals: { article: @article2 }, formats: [:html])
    respond_to do |format|
      format.html { render 'articles/new' }
      format.json { render json: {form: @html_content } }
    end
  end

  # POST /article2s
  def create
    authorize Article2.new
    
    result = Article2Commands.create_article(
      article2_params[:title],
      article2_params[:content],
      current_user
    )
    
    if result[:success]
      @article2 = result[:article2]
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), notice: 'Article was successfully created.' }
        format.json { render json: { success: true, article: @article2 }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render 'articles/new', status: :unprocessable_entity }
        format.json { render json: { success: false, errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end

  # Event Sourcing Actions
  def submit
    result = Article2Commands.submit_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article submitted for review.')
  end

  def reject_feedback
    authorize @article2, :reject?
    @html_content = render_to_string(partial: 'articles/reject_feedback_form', formats: [:html])
    respond_to do |format|
      format.html { render 'articles/reject_feedback' }
      format.json { render json: { form: @html_content } }
    end
  end

  def reject
    result = Article2Commands.reject_article(
      @article2.id,
      params[:rejection_feedback],
      current_user
    )
    
    handle_command_result(result, 'Article rejected.')
  end

  def approve_private
    result = Article2Commands.approve_private_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article approved as private.')
  end

  def resubmit
    result = Article2Commands.resubmit_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article resubmitted for review.')
  end

  def archive
    result = Article2Commands.archive_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article archived.')
  end

  def publish
    result = Article2Commands.publish_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article published.')
  end

  def make_visible
    result = Article2Commands.make_visible_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article made visible.')
  end

  def make_invisible
    result = Article2Commands.make_invisible_article(
      @article2.id,
      current_user
    )
    
    handle_command_result(result, 'Article made private.')
  end

  private

  def set_article2
    @article2 = Article2.find(params[:id])
  end

  def article2_params
    params.require(:article2).permit(:title, :content)
  end

  def rendering_article2s(article2s, title)
    rendered_article2s = ArticleBlueprint.render_as_hash(article2s, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'articles/list', locals: { articles: rendered_article2s, title: title }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_index(current_user)

    respond_to do |format|
      format.html { render "articles/index" }
      format.json { render json: { articles: rendered_article2s, links: @links } }
    end
  end

  def handle_command_result(result, success_message)
    if result[:success]
      @article2 = result[:article2]
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), notice: 'Transition applied.' }
        format.json do
          rendered_article2 = ArticleBlueprint.render_as_hash(@article2, view: :show, context: { current_user: current_user })
          render json: { success: true, article: rendered_article2 }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), alert: result[:errors] }
        format.json { render json: { success: false, errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end
end
