class Comment2sController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_article2, only: [:new, :create]
  before_action :set_comment2, only: [:show, :edit, :update, :approve, :reject, :reject_feedback, :delete, :restore]

  def pending_comment2s
    comment2s = Comment2ReadModel.where(state: 'pending')
  
    rendered_comment2s = comment2s.map { |c| { id: c.id, text: c.text_latest, author_id: c.author_id, article2_id: c.article2_id, state: c.state } }
    @html_content = render_to_string(partial: 'comment2s/list', locals: { comment2s: rendered_comment2s, title: 'Pending Comments' }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_index(current_user, 'Comment2')

    respond_to do |format|
      format.html { render :index }
      format.json { render json: { comments: rendered_comment2s, links: @links } }
    end
  end

  def show
    payload = { id: @comment2.id, text: @comment2.text_latest, author_id: @comment2.author_id, state: @comment2.state, article2_id: @comment2.article2_id }
    @html_content = render_to_string(partial: 'comment2s/comment2', locals: { comment2: payload }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :show }
      format.json { render json: { comment: payload, links: @links } }
    end
  end

  def new
    authorize Comment2, :new?
    @html_content = render_to_string(partial: 'comment2s/form', locals: { comment2: nil }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :new }
      format.json { render json: { links: @links } }
    end
  end

  def create
    authorize Comment2, :create?
    
    result = Comment2Commands.create_comment(
      comment2_params[:text],
      params[:article2_id],
      current_user
    )
    
    if result[:success]
      @comment2 = Comment2ReadModel.find(result[:comment2_id]) rescue nil
      respond_to do |format|
        format.html { redirect_to comment2_path(result[:comment2_id]), notice: 'Comment was successfully created.' }
        format.json { render json: { comment2_id: result[:comment2_id] }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end


  def edit
    authorize Comment2.new, :update?
    @html_content = render_to_string(partial: 'comment2s/form', locals: { comment2: @comment2 }, formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :edit }
      format.json { render json: { comment2: @comment2.slice(:id, :text, :status, :user_id), links: @links } }
    end
  end

  def update
    authorize Comment2.new, :update?
    
    result = Comment2Commands.update_comment(
      params[:id],
      comment2_params[:text],
      current_user
    )
    
    if result[:success]
      id = result[:comment2_id]
      respond_to do |format|
        format.html { redirect_to comment2_path(id), notice: 'Comment was successfully updated.' }
        format.json { render json: { comment2_id: id }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end

  # Event Sourcing Actions
  def approve
    result = Comment2Commands.approve_comment(
      params[:id],
      current_user
    )
    
    handle_command_result(result, 'Comment approved.')
  end

  def reject_feedback
    authorize :comment2, :reject?
    @html_content = render_to_string(partial: 'comment2s/reject_feedback_form', formats: [:html])
    @links = HasHypermediaLinks.hypermedia_general_show(current_user, 'Comment2')
    respond_to do |format|
      format.html { render :reject_feedback }
      format.json { render json: { comment2: @comment2.slice(:id, :text, :status, :user_id), links: @links } }
    end
  end

  def reject
    if params[:rejection_feedback].present?
      result = Comment2Commands.reject_comment(
        params[:id],
        params[:rejection_feedback],
        current_user
      )
      
      handle_command_result(result, 'Comment rejected.')
    else
      respond_to do |format|
        format.html { redirect_to reject_feedback_comment2_path(@comment2), alert: 'Rejection feedback is required.' }
        format.json { render json: { errors: ['Rejection feedback is required.'] }, status: :unprocessable_entity }
      end
    end
  end

  def delete
    result = Comment2Commands.delete_comment(
      params[:id],
      current_user
    )
    
    handle_command_result(result, 'Comment deleted.')
  end

  def restore
    result = Comment2Commands.restore_comment(
      params[:id],
      current_user
    )
    
    handle_command_result(result, 'Comment restored.')
  end

  private

  def set_article2
    @article2 = Article2ReadModel.find(params[:article2_id])
  end

  def set_comment2
    @comment2 = Comment2ReadModel.find(params[:id])
  end

  def comment2_params
    params.require(:comment2).permit(:text)
  end

  def handle_command_result(result, success_message)
    if result[:success]
      id = result[:comment2_id] || params[:id]
      respond_to do |format|
        format.html { redirect_to comment2_path(id), notice: 'Transition applied.' }
        format.json do
          render json: { comment2_id: id, message: success_message }, status: :ok
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to comment2_path(params[:id]), alert: result[:errors] }
        format.json { render json: { errors: [result[:errors]] }, status: :unprocessable_entity }
      end
    end
  end
end
