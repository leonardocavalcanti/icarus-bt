class BugsController < ApplicationController
    before_filter do
        @base_url = "http://#{request.host}"

        @project_url = "http://#{request.host}/projects/#{params[:project_id]}"
        @bug_url = "http://#{request.host}/projects/#{params[:project_id]}/bugs/#{params[:id]}"
    end

    require 'slack-notifier'

    def initialize
        super()

        @notifier = Slack::Notifier.new Rails.application.config.slack_webhook_url
        @formatter = Slack::Notifier::Util::LinkFormatter
    end

    def new
        @bug = Bug.new
        @bug.project = Project.find(params[:project_id])
        @state = params[:state]
    end
    
    def edit
        @bug = Bug.find(params[:id])
    end

    def create
        @bug = Bug.new(bug_params)

        @bug.project = Project.find(params[:project_id])

        unless params.require(:bug)[:user_id].to_s.empty?
            @bug.user = User.find(params.require(:bug)[:user_id])
        end
        
        if @bug.save
            notify_new_bug(@bug, @bug.project, @bug.user != nil ? @bug.user.name : nil)

            redirect_to @bug.project
        else
            render 'new'
        end
    end

    def update
        @bug = Bug.find(params[:id])
        

        @bug.project = Project.find(params[:project_id])

        user_removed = params.require(:bug)[:user_id].to_s.empty? && @bug.user != nil

        unless params.require(:bug)[:user_id].to_s.empty?
            @bug.user = User.find(params.require(:bug)[:user_id])
        else
            @bug.user = nil
        end
        
        state_changed = @bug.state != params.require(:bug)[:state]
        user_changed = !params.require(:bug)[:user_id].to_s.empty? && @bug.user.id != params.require(:bug)[:user_id]

        if @bug.update(bug_params)
            if user_removed
                notify_bug_user_removed(@bug.id, @bug.description, @bug.project.name, state_changed ? params.require(:bug)[:state] : nil)
            elsif user_changed
                notify_bug_user_changed(@bug.id, @bug.description, @bug.project.name, @bug.user.name, state_changed ? params.require(:bug)[:state] : nil)
            elsif state_changed
                notify_bug_state_changed(@bug.id, @bug.description, @bug.project.name, params.require(:bug)[:state])
            end

            redirect_to @bug.project
        else
            render 'edit'
        end
    end

    def change_state
        @bug = Bug.find(params[:id])
        
        if @bug.update(:state => params[:state])
            notify_bug_state_changed(@bug.id, @bug.description, @bug.project.name, params[:state])
        end
    end

    def destroy
        @bug = Bug.find(params[:id])
        @bug.destroy

        notify_bug_removed(@bug.id, @bug.description, @bug.project.name)

        redirect_back(fallback_location: root_path)
    end
  
    def show
        @bug = Bug.find(params[:id])
    end

    private
        def bug_params
            params.require(:bug).permit(:description, :steps, :state)
        end

        def notify_new_bug(bug, project, user_name)
            message = @formatter.format("*#{current_user.name}* criou o bug <a href='#{@bug_url}#{bug.id}'>#{bug.id} - #{bug.description}</a>, no projeto <a href='#{@project_url}'>#{project.name}</a>")
            unless user_name.to_s.empty?
                message += " e o atriubuiu à *#{user_name}*"
            end
            @notifier.ping message
        end

        def notify_bug_user_changed(bug_id, bug_description, project_name, user_name, state)
            if state.to_s.empty?
                @notifier.ping @formatter.format("*#{current_user.name}* atribuiu o bug <a href='#{@bug_url}'>#{bug_id} - #{bug_description}</a>, do projeto <a href='#{@project_url}'>#{project_name}</a>, à *#{user_name}*")
            else
                @notifier.ping @formatter.format("*#{current_user.name}* moveu o bug <a href='#{@bug_url}'>#{bug_id} - #{bug_description}</a>, do projeto <a href='#{@project_url}'>#{project_name}</a>, para *#{state}* e o atribuiu à *#{user_name}*")
            end

        end

        def notify_bug_user_removed(bug_id, bug_description, project_name, state)
            if state.to_s.empty?
                @notifier.ping @formatter.format("*#{current_user.name}* removeu a atribuição do bug <a href='#{@bug_url}'>#{bug_id} - #{bug_description}</a>, do projeto <a href='#{@project_url}'>#{project_name}</a>")
            else
                @notifier.ping @formatter.format("*#{current_user.name}* moveu o bug <a href='#{@bug_url}'>#{bug_id} - #{bug_description}</a>, do projeto <a href='#{@project_url}'>#{project_name}</a>, para *#{state}* e removeu a sua atribuição")
            end

        end

        def notify_bug_state_changed(bug_id, bug_description, project_name, state)
            @notifier.ping @formatter.format("*#{current_user.name}* moveu o bug <a href='#{@bug_url}'>#{bug_id} - #{bug_description}</a>, do projeto <a href='#{@project_url}'>#{project_name}</a>, para *#{state}*")
        end

        def notify_bug_removed(bug_id, bug_description, project_name)
            @notifier.ping @formatter.format("*#{current_user.name}* removeu o bug *#{bug_id} - #{bug_description}*, do projeto <a href='#{@project_url}'>#{project_name}</a>")
        end

end
