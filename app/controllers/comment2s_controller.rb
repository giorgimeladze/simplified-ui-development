class Comment2sController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_article2, only: [:new, :create]
  before_action :set_comment2, only: [:show, :destroy, :approve, :reject, :reject_feedback, :delete, :restore]

  def pending_comment2s
    comment2s = Comment2.pending
  
    rendered_comment2s = CommentBlueprint.render_as_hash(comment2s, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'list', locals: { comments: rendered_comment2s, title: 'Pending Comments' }, formats: [:html])

    respond_to do |format|
      format.html { render 'comments/index' }
      format.json { render json: { comments: rendered_comment2s } }
    end
  end

  def show
    rendered_comment2 = CommentBlueprint.render_as_hash(@comment2, view: :show, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'comment', locals: { comment: rendered_comment2 }, formats: [:html])

    respond_to do |format|
      format.html { render 'comments/show' }
      format.json { render json: { comment: @html_content } }
    end
  end

  def new
    @comment2 = @article2.comment2s.build
    authorize @comment2
    @html_content = render_to_string(partial: 'form', locals: { comment: @comment2 }, formats: [:html])
    respond_to do |format|
      format.html { render 'comments/new' }
      format.json { render json: {form: @html_content } }
    end
  end

  def create
    @comment2 = @article2.comment2s.build(comment2_params)
    @comment2.user = current_user
    authorize @comment2

    if @comment2.save
      respond_to do |format|
        format.html { redirect_to comment2_path(@comment2), notice: 'Comment was successfully created.' }
        format.json { render json: { success: true, comment: @comment2 }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render 'comments/new', status: :unprocessable_entity }
        format.json { render json: { success: false, errors: @comment2.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize @comment2
    @comment2.destroy
    respond_to do |format|
      format.html { redirect_to article2_path(@comment2.article2), notice: 'Comment deleted.' }
      format.json { head :no_content }
    end
  end

  # FSM Transition Actions
  def approve
    transition_comment2(:approve)
  end

  def reject_feedback
    authorize @comment2, :reject?
    @html_content = render_to_string(partial: 'reject_feedback_form', formats: [:html])
    respond_to do |format|
      format.html { render 'comments/reject_feedback' }
      format.json { render json: { form: @html_content } }
    end
  end

  def reject
    if params[:rejection_feedback].present?
      @comment2.update(rejection_feedback: params[:rejection_feedback])
      transition_comment2(:reject)
    else
      respond_to do |format|
        format.html { redirect_to reject_feedback_comment2_path(@comment2), alert: 'Rejection feedback is required.' }
        format.json { render json: { success: false, errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
  end

  def delete
    transition_comment2(:delete)
  end

  def restore
    transition_comment2(:restore)
  end

  private

  def set_article2
    @article2 = Article2.find(params[:article2_id])
  end

  def set_comment2
    @comment2 = Comment2.find(params[:id])
  end

  def comment2_params
    params.require(:comment2).permit(:text)
  end

  def transition_comment2(event)
    # Event-level authorization
    policy = Comment2Policy.new(current_user, @comment2)
    unless policy.respond_to?("#{event}?") && policy.public_send("#{event}?")
      raise Pundit::NotAuthorizedError
    end

    if @comment2.aasm.may_fire_event?(event)
      @comment2.aasm.fire!(event)
      respond_to do |format|
        format.html { redirect_to article2_path(@comment2.article2), notice: 'Transition applied.' }
        format.json do
          rendered_comment2 = CommentBlueprint.render_as_hash(@comment2, view: :show, context: { current_user: current_user })
          render json: { success: true, comment: rendered_comment2 }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article2_path(@comment2.article2), alert: 'Transition not allowed.' }
        format.json { render json: { success: false, errors: @comment2.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end
end
