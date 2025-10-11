class CommentsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_article, only: [:new, :create]
  before_action :set_comment, only: [:show, :destroy, :approve, :delete, :restore]

  def pending_comments
    comments = Comment.pending
  
    rendered_comments = CommentBlueprint.render_as_hash(comments, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'list', locals: { comments: rendered_comments, title: 'Pending Comments' })

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { comments: rendered_comments } }
    end
  end

  def show
    rendered_comment = CommentBlueprint.render_as_hash(@comment, view: :show, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'comment', locals: { comment: rendered_comment })

    respond_to do |format|
      format.html { render :show }
      format.json { render json: { comment: @html_content } }
    end
  end

  def new
    @comment = @article.comments.build
    authorize @comment
    @html_content = render_to_string(partial: 'form', locals: { comment: @comment })
    respond_to do |format|
      format.html { render :new }
      format.json { render json: {form: @html_content } }
    end
  end

  def create
    @comment = @article.comments.build(comment_params)
    @comment.user = current_user
    authorize @comment

    if @comment.save
      respond_to do |format|
        format.html { redirect_to comment_path(@comment), notice: 'Comment was successfully created.' }
        format.json { render json: { success: true, comment: @comment }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @comment
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to article_path(@comment.article), notice: 'Comment deleted.' }
      format.json { head :no_content }
    end
  end

  # FSM Transition Actions
  def approve
    transition_comment(:approve)
  end

  def delete
    transition_comment(:delete)
  end

  def restore
    transition_comment(:restore)
  end

  private

  def set_article
    @article = Article.find(params[:article_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:text)
  end

  def transition_comment(event)
    # Event-level authorization
    policy = CommentPolicy.new(current_user, @comment)
    unless policy.respond_to?("#{event}?") && policy.public_send("#{event}?")
      raise Pundit::NotAuthorizedError
    end

    if @comment.aasm.may_fire_event?(event)
      @comment.aasm.fire!(event)
      respond_to do |format|
        format.html { redirect_to article_path(@comment.article), notice: 'Transition applied.' }
        format.json do
          rendered_comment = CommentBlueprint.render_as_hash(@comment, view: :show, context: { current_user: current_user })
          render json: { success: true, comment: rendered_comment }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article_path(@comment.article), alert: 'Transition not allowed.' }
        format.json { render json: { success: false, errors: @comment.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end