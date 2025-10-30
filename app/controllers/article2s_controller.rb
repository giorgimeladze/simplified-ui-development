class Article2sController < ApplicationController  
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_article2, only: [:show, :submit, :reject, :reject_feedback, :approve_private, :resubmit, :archive, :publish, :make_visible, :make_invisible]

  def index
    article2s = Article2ReadModel.all
    render_article2s_list(article2s, 'All Articles')
  end
  
  def my_article2s
    article2s = Article2ReadModel.by_author(current_user.id)
    render_article2s_list(article2s, 'My Articles')
  end
  
  def article2s_for_review
    authorize :article2, :article2s_for_review?
    article2s = Article2ReadModel.where(state: 'review')
    render_article2s_list(article2s, 'Articles for Review')
  end
  
  def deleted_article2s
    authorize :article2, :deleted_article2s?
    base = current_user.admin? ? Article2ReadModel.all : Article2ReadModel.by_author(current_user.id)
    article2s = base.where(state: 'archived')
    render_article2s_list(article2s, 'Archived Articles')
  end

   # GET /article2s/:id
   def show
    comments = Comment2ReadModel.for_article(@article2.id)
    payload = {
      id: @article2.id,
      title: @article2.title,
      content: @article2.content_latest,
      author_id: @article2.author_id,
      state: @article2.state,
      _embedded: {
        comment2s: comments.map { |c| { id: c.id, text: c.text_latest, author_id: c.author_id, state: c.state } }
      }
    }
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Article2')
    respond_to do |format|
      format.html { render :show, locals: { article2: payload } }
      format.json { render json: { article2: payload, links: @links } }
    end
  end

  # GET /article2s/new
  def new
    @article2 = Article2.new
    authorize :article2, :new?
    @html_content = render_to_string(partial: 'article2s/form', locals: { article2: @article2 }, formats: [:html])
    @links = @article2.hypermedia_new_links(current_user)
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { article2: @article2, links: @links } }
    end
  end

  # POST /article2s
  def create
    authorize :article2, :create?
    
    result = Article2Commands.create_article(
      article2_params[:title],
      article2_params[:content],
      current_user
    )
    
    if result[:success]
      @article2 = Article2ReadModel.find(result[:article2_id]) rescue nil
      respond_to do |format|
        format.html { redirect_to article2_path(result[:article2_id]), notice: 'Article was successfully created.' }
        format.json { render json: { article2_id: result[:article2_id] }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: [result[:errors]] }, status: :unprocessable_entity }
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
    authorize :article2, :reject?
    @html_content = render_to_string(partial: 'article2s/reject_feedback_form', formats: [:html])
    @links = @article2.hypermedia_edit_links(current_user)
    respond_to do |format|
      format.html { render :reject_feedback }
      format.json { render json: { article2: @article2.slice(:id, :title, :content, :status, :user_id), links: @links } }
    end
  end

  def reject
    if params[:rejection_feedback].present?
      result = Article2Commands.reject_article(
        @article2.id,
        params[:rejection_feedback],
        current_user
      )
      
      handle_command_result(result, 'Article rejected.')
    else  
      respond_to do |format|
        format.html { redirect_to reject_feedback_article2_path(@article2), alert: 'Rejection feedback is required.' }
        format.json { render json: { errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
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
    @article2 = Article2ReadModel.find(params[:id])
  end

  def article2_params
    params.require(:article2).permit(:title, :content)
  end

  def render_article2s_list(article2s, title)
    list = article2s.map { |a| { id: a.id, title: a.title, state: a.state, author_id: a.author_id } }
    @links = HasHypermediaLinks.hypermedia_general_index(current_user, 'Article2')
    respond_to do |format|
      format.html { render :index, locals: { article2s: list, title: title } }
      format.json { render json: { articles: list, links: @links } }
    end
  end

  def handle_command_result(result, success_message)
    if result[:success]
      id = result[:article2_id] || params[:id]
      respond_to do |format|
        format.html { redirect_to article2_path(id), notice: 'Transition applied.' }
        format.json do
          render json: { article2_id: id, message: success_message }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article2_path(params[:id]), alert: result[:errors] }
        format.json { render json: { errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end
end
