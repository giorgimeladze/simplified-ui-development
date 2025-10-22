class Article2sController < ApplicationController  
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_article2, only: [:show, :submit, :reject, :reject_feedback, :approve_private, :resubmit, :archive, :publish, :make_visible, :make_invisible, :destroy]

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
    @article2 = Article2.new(article2_params)
    @article2.user = current_user
    authorize @article2

    if @article2.save
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), notice: 'Article was successfully created.' }
        format.json { render json: { success: true, article: @article2 }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render 'articles/new', status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @article2.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /article2s/:id
  def destroy
    authorize @article2
    @article2.destroy
    respond_to do |format|
      format.html { redirect_to article2s_path, notice: 'Article deleted.' }
      format.json { head :no_content }
    end
  end

  # FSM Event Actions
  def submit
    transition_article2(:submit)
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
    if params[:rejection_feedback].present?
      @article2.update(rejection_feedback: params[:rejection_feedback])
      transition_article2(:reject)
    else
      respond_to do |format|
        format.html { redirect_to reject_feedback_article2_path(@article2), alert: 'Rejection feedback is required.' }
        format.json { render json: { success: false, errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
  end

  def approve_private
    transition_article2(:approve_private)
  end

  def resubmit
    transition_article2(:resubmit)
  end

  def archive
    transition_article2(:archive)
  end

  def publish
    transition_article2(:publish)
  end

  def make_visible
    transition_article2(:make_visible)
  end

  def make_invisible
    transition_article2(:make_invisible)
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

  def transition_article2(event)
    # Event-level authorization
    policy = Article2Policy.new(current_user, @article2)
    unless policy.respond_to?("#{event}?") && policy.public_send("#{event}?")
      raise Pundit::NotAuthorizedError
    end

    if @article2.aasm.may_fire_event?(event)
      @article2.aasm.fire!(event)
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), notice: 'Transition applied.' }
        format.json do
          rendered_article2 = ArticleBlueprint.render_as_hash(@article2, view: :show, context: { current_user: current_user })
          render json: { success: true, article: rendered_article2 }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article2_path(@article2), alert: 'Transition not allowed.' }
        format.json { render json: { success: false, errors: @article2.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
