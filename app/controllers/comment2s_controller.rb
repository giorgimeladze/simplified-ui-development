class Comment2sController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_article2, only: [:new, :create]
  before_action :set_comment2, only: [:show, :edit, :update, :approve, :reject, :reject_feedback, :delete, :restore]

  def pending_comment2s
    comment2s = Comment2.awaiting_moderation
  
    rendered_comment2s = CommentBlueprint.render_as_hash(comment2s, view: :index, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'comment2s/list', locals: { comment2s: rendered_comment2s, title: 'Pending Comments' }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_index(current_user, 'Comment2')

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { comments: rendered_comment2s, links: @links } }
    end
  end

  def show
    rendered_comment2 = CommentBlueprint.render_as_hash(@comment2, view: :show, context: { current_user: current_user })
    @html_content = render_to_string(partial: 'comment2s/comment2', locals: { comment2: rendered_comment2 }, formats: [:html])
    @links = @comment2.article2.hypermedia_edit_links(current_user)
    respond_to do |format|
      format.html { render :show }
      format.json { render json: { comment: rendered_comment2, links: @links } }
    end
  end

  def new
    @comment2 = @article2.comment2s.build
    authorize @comment2
    @html_content = render_to_string(partial: 'comment2s/form', locals: { comment2: @comment2 }, formats: [:html])
    @links = @article2.hypermedia_edit_links(current_user)
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { comment: @comment2, links: @links } }
    end
  end

  def create
    authorize Comment2.new
    
    result = Comment2Commands.create_comment(
      comment2_params[:text],
      @article2.id,
      current_user
    )
    
    if result[:success]
      @comment2 = result[:comment2]
      respond_to do |format|
        format.html { redirect_to comment2_path(@comment2), notice: 'Comment was successfully created.' }
        format.json { render json: { success: true, comment: @comment2 }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end


  def edit
    authorize @comment2, :update?
    @html_content = render_to_string(partial: 'comment2s/form', locals: { comment2: @comment2 }, formats: [:html])
    @links = @comment2.hypermedia_edit_links(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { comment2: @comment2, links: @links } }
    end
  end

  def update
    authorize @comment2, :update?
    
    result = Comment2Commands.update_comment(
      @comment2.id,
      comment2_params[:text],
      current_user
    )
    
    if result[:success]
      @comment2 = result[:comment2]
      respond_to do |format|
        format.html { redirect_to comment2_path(@comment2), notice: 'Comment was successfully updated.' }
        format.json { render json: { success: true, comment: @comment2 }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { success: false, errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end

  # Event Sourcing Actions
  def approve
    result = Comment2Commands.approve_comment(
      @comment2.id,
      current_user
    )
    
    handle_command_result(result, 'Comment approved.')
  end

  def reject_feedback
    authorize @comment2, :reject?
    @html_content = render_to_string(partial: 'comment2s/reject_feedback_form', formats: [:html])
    @links = @comment2.hypermedia_edit_links(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :reject_feedback }
      format.json { render json: { comment2: @comment2, links: @links } }
    end
  end

  def reject
    if params[:rejection_feedback].present?
      result = Comment2Commands.reject_comment(
        @comment2.id,
        params[:rejection_feedback],
        current_user
      )
      
      handle_command_result(result, 'Comment rejected.')
    else
      respond_to do |format|
        format.html { redirect_to reject_feedback_comment2_path(@comment2), alert: 'Rejection feedback is required.' }
        format.json { render json: { success: false, errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
  end

  def delete
    result = Comment2Commands.delete_comment(
      @comment2.id,
      current_user
    )
    
    handle_command_result(result, 'Comment deleted.')
  end

  def restore
    result = Comment2Commands.restore_comment(
      @comment2.id,
      current_user
    )
    
    handle_command_result(result, 'Comment restored.')
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

  def handle_command_result(result, success_message)
    if result[:success]
      @comment2 = result[:comment2]
      respond_to do |format|
        format.html { redirect_to article2_path(@comment2.article2), notice: 'Transition applied.' }
        format.json do
          rendered_comment2 = CommentBlueprint.render_as_hash(@comment2, view: :show, context: { current_user: current_user })
          render json: { success: true, comment: rendered_comment2 }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to article2_path(@comment2.article2), alert: result[:errors] }
        format.json { render json: { success: false, errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end
end
