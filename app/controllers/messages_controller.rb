class MessagesController < ApplicationController
  before_action :correct_user, only: [:show]

  def create
    if(params[:conversation_id])
      @conversation = Conversation.includes(:recipient).find(params[:conversation_id])
      @message = @conversation.messages.create(message_params)
    else
      content = params[:message][:content]
      recipient = User.find(params[:message][:user_id])
      @conversation = Conversation.get(current_user.id, params[:message][:user_id])
      @relationship = Relationship.between(recipient, current_user).first
      if (@relationship.status == 3) && (@relationship.block_id.to_s == params[:message][:user_id] || @relationship.block_id == -1)
        redirect_to messages_path, alert: "You have been blocked by #{recipient.name}" and return
      else
        @message = @conversation.messages.create(content: content, user: current_user, image: params[:message][:image])
      end
    end

    respond_to do |format|
      recipient = @conversation.opposed_user(current_user)
      MessageMailer.sent_notice(recipient, @message).deliver_later
      format.js
    end

  end

  def index
    if (session[:show_message])
      @message = Message.find(session[:show_message])
      @recipient = @message.conversation.opposed_user(@message.user)
      session[:show_message] = nil
    else
      # For loading messages
      conversations = Conversation.get_all(current_user.id)
      @messages = conversations.collect(&:messages)
      @messages.flatten!
      if @messages
        @messages.uniq!
        @messages.delete_if { |message| message.user == current_user }
        @messages.sort!{ |a, b| b.created_at <=> a.created_at }
      end
    end
    # For create new message
    @new_message = Message.new
    @users = Array.new
    @relationships = Relationship.includes(:user_one).where("user_one_id = ? or user_two_id = ?", current_user.id, current_user.id)
    @relationships.each do |relationship|
      friend = User.find_friend(current_user, relationship)
      @users << User.find(friend)
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def sent
    @messages = current_user.messages
  end

  def show
    if (@message.user != current_user) && (!@message.seen_at)
      MessageMailer.seen_notice(@recipient, @message).deliver_later
      @message.update(seen_at: DateTime.now)
    end
    respond_to do |format|
      format.html do
        session[:show_message] = @message.id
        redirect_to messages_path
      end
      format.js
    end
  end

  private
    def message_params
      params.require(:message).permit(:user_id, :content)
    end

    def correct_user
      begin
        @message = Message.find(params[:id])
        @recipient = @message.conversation.opposed_user(@message.user)
      rescue ActiveRecord::RecordNotFound => e
        respond_to do |format|
          format.html do
            redirect_to '/404' and return
          end
          format.js do
            head 404
          end
        end
      else
        if (@message.user != current_user) && (@recipient != current_user)
          redirect_to '/404' and return
        end
      end
    end
end
